import 'dart:async';

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

  late final sdk.Room room = sdk.Room(roomOptions: const sdk.RoomOptions(enableVisualizer: true));
  late final roomContext = components.RoomContext(room: room);
  // Removed 'final' to allow session replacement
  late sdk.Session session = _createSession(room: room);

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

  Future<void> connect() async {
    if (isSessionStarting) {
      _logger.fine('Connection attempt ignored: session already starting.');
      return;
    }

    _logger.info('Starting session connection…');
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
      final liveKitToken = await _tokenRepo.getToken(accessToken, 'my-test-room');

      // 3. Connect using the logic from prompt
      final url = dotenv.env['LIVEKIT_URL']?.replaceAll('"', '') ?? '';

      await _connectToRoom(url, liveKitToken);

      if (session.connectionState == sdk.ConnectionState.connected) {
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

    final newSession = sdk.Session.fromFixedTokenSource(
      sdk.LiteralTokenSource(
        serverUrl: url,
        participantToken: token,
      ),
      options: sdk.SessionOptions(room: room),
    );

    session = newSession;
    session.addListener(_handleSessionChange);

    await session.start();
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
      notifyListeners();
    }
  }
}
