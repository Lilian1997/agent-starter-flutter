import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../support/auth_repository.dart';
import '../support/livekit_token_repository.dart';


enum AppScreenState { login, welcome, agent }

enum AgentScreenState { visualizer, transcription }

/// Represents a message from another participant in the room (not the agent)
class PeerMessage {
  final String id;
  final String participantIdentity;
  final String text;
  final DateTime timestamp;

  const PeerMessage({
    required this.id,
    required this.participantIdentity,
    required this.text,
    required this.timestamp,
  });

  @override
  String toString() => 'PeerMessage(id: $id, from: $participantIdentity, text: $text)';
}

/// Enum to identify the sender type of a message
enum MessageSender {
  agent,      // Agent's transcript
  user,       // User's own message (input or transcript)
  peer,       // Other participant's message
}

/// Unified message wrapper for displaying all message types in one chat
class UnifiedChatMessage {
  final String id;
  final String text;
  final DateTime timestamp;
  final MessageSender sender;
  final String? senderName; // For peer messages

  const UnifiedChatMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.sender,
    this.senderName,
  });

  /// Create from SDK ReceivedMessage
  factory UnifiedChatMessage.fromSessionMessage(sdk.ReceivedMessage msg) {
    final content = msg.content;
    MessageSender sender;
    
    if (content is sdk.AgentTranscript) {
      sender = MessageSender.agent;
    } else if (content is sdk.UserInput || content is sdk.UserTranscript) {
      sender = MessageSender.user;
    } else {
      sender = MessageSender.agent; // Default fallback
    }

    return UnifiedChatMessage(
      id: msg.id,
      text: content.text,
      timestamp: msg.timestamp,
      sender: sender,
    );
  }

  /// Create from PeerMessage
  factory UnifiedChatMessage.fromPeerMessage(PeerMessage msg) {
    return UnifiedChatMessage(
      id: msg.id,
      text: msg.text,
      timestamp: msg.timestamp,
      sender: MessageSender.peer,
      senderName: msg.participantIdentity,
    );
  }
}

class AppCtrl extends ChangeNotifier {
  static const uuid = Uuid();
  static final _logger = Logger('AppCtrl');

  // States
  AppScreenState appScreenState = AppScreenState.login;
  AgentScreenState agentScreenState = AgentScreenState.visualizer;

  // Repositories - use singleton for AuthRepository
  final _authRepo = AuthRepository.instance;
  final _tokenRepo = LiveKitTokenRepository(Dio());

  //Test
  bool isUserCameEnabled = false;
  bool isScreenshareEnabled = false;

  final messageCtrl = TextEditingController();
  final messageFocusNode = FocusNode();

  // Peer messages from other participants (not the agent)
  final List<PeerMessage> peerMessages = [];

  late final sdk.Room room = sdk.Room(roomOptions: const sdk.RoomOptions(enableVisualizer: true));
  late final roomContext = components.RoomContext(room: room);
  // Removed 'final' to allow session replacement
  late sdk.Session session = _createSession(room: room);
  
  // Room event listener for peer messages
  sdk.EventsListener<sdk.RoomEvent>? _roomListener;

  /// Get all messages (session + peer) merged and sorted by timestamp
  List<UnifiedChatMessage> get allMessages {
    final List<UnifiedChatMessage> unified = [];
    final Set<String> seenIds = {};
    
    // Add session messages (Agent transcripts + User messages)
    for (final msg in session.messages) {
      if (msg.content.text.trim().isNotEmpty && !seenIds.contains(msg.id)) {
        unified.add(UnifiedChatMessage.fromSessionMessage(msg));
        seenIds.add(msg.id);
      }
    }
    
    // Add peer messages
    for (final msg in peerMessages) {
      if (msg.text.trim().isNotEmpty && !seenIds.contains(msg.id)) {
        unified.add(UnifiedChatMessage.fromPeerMessage(msg));
        seenIds.add(msg.id);
      }
    }
    
    // Sort by timestamp
    unified.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return unified;
  }

  static sdk.Session _createSession({required sdk.Room room}) {
    // We can use a default sandbox or dev setup for initial state
    final devServerUrl = dotenv.env['LIVEKIT_URL']?.replaceAll('"', '');
    final devToken = dotenv.env['LIVEKIT_TOKEN']?.replaceAll('"', '');

    if (devServerUrl != null && devToken != null) {
      return sdk.Session.fromFixedTokenSource(
        sdk.LiteralTokenSource(
          serverUrl: devServerUrl,
          participantToken: devToken,
        ),
        options: sdk.SessionOptions(room: room),
      );
    }

    // Fallback to sandbox or placeholder if needed.
    // If no config, we might crash if we try to use it, but for now restoration of original logic is safest.
    final sandboxId = dotenv.env['LIVEKIT_SANDBOX_ID']?.replaceAll('"', '');
    if (sandboxId != null && sandboxId.isNotEmpty) {
      return sdk.Session.fromConfigurableTokenSource(
        sdk.SandboxTokenSource(sandboxId: sandboxId).cached(),
        options: sdk.SessionOptions(room: room),
      );
    }

    // Fallback for when we really don't have anything (should rely on connect() later)
    // We create a dummy session that won't connect but satisfies the type.
    return sdk.Session.fromFixedTokenSource(
      sdk.LiteralTokenSource(
        serverUrl: '',
        participantToken: '',
      ),
      options: sdk.SessionOptions(room: room),
    );
  }

  bool isSendButtonEnabled = false;
  bool isSessionStarting = false;
  bool _hasCleanedUp = false;

  AppCtrl() {
    final format = DateFormat('HH:mm:ss');
    // configure logs for debugging
    Logger.root.level = Level.FINE;
    Logger.root.onRecord.listen((record) {
      debugPrint('${format.format(record.time)}: ${record.message}');
    });

    messageCtrl.addListener(() {
      final newValue = messageCtrl.text.isNotEmpty;
      if (newValue != isSendButtonEnabled) {
        isSendButtonEnabled = newValue;
        notifyListeners();
      }
    });

    session.addListener(_handleSessionChange);

    // Check initial auth state
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = await _authRepo.checkAuth();
    if (token != null) {
      appScreenState = AppScreenState.welcome;
    } else {
      appScreenState = AppScreenState.login;
    }
    notifyListeners();
  }

  Future<void> login() async {
    final token = await _authRepo.login();
    if (token != null) {
      appScreenState = AppScreenState.welcome;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    appScreenState = AppScreenState.login;
    notifyListeners();
  }

  Future<void> cleanUp() async {
    if (_hasCleanedUp) return;
    _hasCleanedUp = true;

    _roomListener?.dispose();
    session.removeListener(_handleSessionChange);
    await session.dispose();
    await room.dispose();
    roomContext.dispose();
    messageCtrl.dispose();
    messageFocusNode.dispose();
  }

  @override
  void dispose() {
    unawaited(cleanUp());
    super.dispose();
  }

  void sendMessage() async {
    isSendButtonEnabled = false;

    final text = messageCtrl.text;
    messageCtrl.clear();
    notifyListeners();

    if (text.isEmpty) return;
    await session.sendText(text);
  }

  void toggleUserCamera(components.MediaDeviceContext? deviceCtx) {
    isUserCameEnabled = !isUserCameEnabled;
    isUserCameEnabled ? deviceCtx?.enableCamera() : deviceCtx?.disableCamera();
    notifyListeners();
  }

  void toggleScreenShare() {
    isScreenshareEnabled = !isScreenshareEnabled;
    notifyListeners();
  }

  void toggleAgentScreenMode() {
    agentScreenState =
        agentScreenState == AgentScreenState.visualizer ? AgentScreenState.transcription : AgentScreenState.visualizer;
    notifyListeners();
  }

  /// 連接到 LiveKit 房間
  /// [roomName] 房間名稱
  /// [nickName] 使用者暱稱（可選）
  Future<void> connect({
    String roomName = 'my-test-room',
    String? nickName,
  }) async {
    if (isSessionStarting) {
      _logger.fine('Connection attempt ignored: session already starting.');
      return;
    }

    _logger.info('Starting session connection to room: $roomName, nickName: $nickName');
    isSessionStarting = true;
    notifyListeners();

    try {
      // 1. Get auth token
      final accessToken = await _authRepo.getAccessToken();
      if (accessToken == null) {
        // If we're here, we're likely on the Welcome screen and should have a token.
        // But if not, we switch back to login state.
        appScreenState = AppScreenState.login;
        notifyListeners();
        return;
      }

      // 2. Get LiveKit token
      final liveKitToken = await _tokenRepo.getToken(
        accessToken,
        roomName,
        nickName: nickName,
      );

      // 3. Connect using the logic from prompt
      final url = dotenv.env['LIVEKIT_URL']?.replaceAll('"', '') ?? '';

      await _connectToRoom(url, liveKitToken);

      if (session.connectionState == sdk.ConnectionState.connected) {
        _logger.warning('Connected to room');
        appScreenState = AppScreenState.agent;
        notifyListeners();
      }
    } catch (e) {
      _logger.severe('Connection error: $e');
    } finally {
      isSessionStarting = false;
      notifyListeners();
    }
  }

  Future<void> _connectToRoom(String url, String token) async {
    session.removeListener(_handleSessionChange);
    await session.dispose();

    // Clear peer messages when reconnecting
    peerMessages.clear();

    final newSession = sdk.Session.fromFixedTokenSource(
      sdk.LiteralTokenSource(
        serverUrl: url,
        participantToken: token,
      ),
      options: sdk.SessionOptions(room: room),
    );

    session = newSession;
    session.addListener(_handleSessionChange);

    // Register handler for peer chat messages (lk.chat topic)
    room.registerTextStreamHandler('lk.chat', _handlePeerTextStream);

    // Listen for legacy data packets using createListener
    _roomListener?.dispose();
    _roomListener = room.createListener();
    _roomListener!.on<sdk.DataReceivedEvent>(_handleDataReceived);

    await session.start();
  }

  /// Handle text stream from other participants (lk.chat topic)
  void _handlePeerTextStream(sdk.TextStreamReader reader, String participantIdentity) async {
    // Don't process our own messages
    if (participantIdentity == room.localParticipant?.identity) return;

    try {
      final text = await reader.readAll();
      if (text.isNotEmpty) {
        final message = PeerMessage(
          id: reader.info?.id ?? uuid.v4(),
          participantIdentity: participantIdentity,
          text: text,
          timestamp: DateTime.now(),
        );
        peerMessages.add(message);
        _logger.info('Received peer message from $participantIdentity: $text');
        notifyListeners();
      }
    } catch (e) {
      _logger.warning('Error reading peer text stream: $e');
    }
  }

  /// Handle legacy data packets (lk-chat-topic)
  void _handleDataReceived(sdk.DataReceivedEvent event) {
    if (event.topic != 'lk-chat-topic') return;

    // Don't process our own messages
    if (event.participant?.identity == room.localParticipant?.identity) return;

    try {
      final jsonStr = utf8.decode(event.data);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final messageText = data['message'] as String?;
      
      if (messageText != null && messageText.isNotEmpty) {
        final message = PeerMessage(
          id: data['id'] as String? ?? uuid.v4(),
          participantIdentity: event.participant?.identity ?? 'Unknown',
          text: messageText,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (data['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
          ),
        );
        peerMessages.add(message);
        _logger.info('Received legacy peer message from ${message.participantIdentity}: $messageText');
        notifyListeners();
      }
    } catch (e) {
      _logger.warning('Error parsing legacy data packet: $e');
    }
  }

  Future<void> disconnect() async {
    await session.end();
    session.restoreMessageHistory(const []);
    appScreenState = AppScreenState.welcome;
    agentScreenState = AgentScreenState.visualizer;
    notifyListeners();
  }

  void _handleSessionChange() {
    final sdk.ConnectionState state = session.connectionState;
    AppScreenState? nextScreen;
    switch (state) {
      case sdk.ConnectionState.connected:
      case sdk.ConnectionState.reconnecting:
        nextScreen = AppScreenState.agent;
        break;
      case sdk.ConnectionState.disconnected:
        nextScreen = AppScreenState.welcome;
        break;
      case sdk.ConnectionState.connecting:
        nextScreen = null;
        break;
    }

    if (nextScreen != null && nextScreen != appScreenState) {
      appScreenState = nextScreen;
    }
    
    // Always notify listeners when session changes (including message updates)
    // This ensures real-time message display works correctly
    notifyListeners();
  }
}
