import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:provider/provider.dart';

import '../controllers/app_ctrl.dart';
import '../support/agent_selector.dart';
import '../widgets/agent_layout_switcher.dart';
import '../widgets/camera_toggle_button.dart';
import '../widgets/message_bar.dart';

class AgentTrackView extends StatelessWidget {
  const AgentTrackView({super.key});

  @override
  Widget build(BuildContext context) => AgentParticipantSelector(
        builder: (ctx, agentParticipant) => Selector<components.ParticipantContext?, sdk.TrackPublication?>(
          selector: (ctx, agentCtx) {
            final videoTrack = agentCtx?.tracks.where((t) => t.kind == sdk.TrackType.VIDEO).firstOrNull;
            final audioTrack = agentCtx?.tracks.where((t) => t.kind == sdk.TrackType.AUDIO).firstOrNull;
            // Prioritize video track
            return videoTrack ?? audioTrack;
          },
          builder: (ctx, mediaTrack, child) => ChangeNotifierProvider<components.TrackReferenceContext?>.value(
            value:
                agentParticipant == null ? null : components.TrackReferenceContext(agentParticipant, pub: mediaTrack),
            child: Builder(
              builder: (ctx) => Container(
                // color: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
                alignment: Alignment.center,
                child: Container(
                  // color: Colors.blue,
                  constraints: const BoxConstraints(maxHeight: 350),
                  child: Builder(builder: (ctx) {
                    final trackReferenceContext = ctx.watch<components.TrackReferenceContext?>();
                    // Switch according to video or audio

                    if (trackReferenceContext?.isVideo ?? false) {
                      return const components.VideoTrackWidget();
                    }

                    return const components.AudioVisualizerWidget(
                      options: components.AudioVisualizerWidgetOptions(
                        barCount: 5,
                        width: 32,
                        minHeight: 32,
                        maxHeight: 320,
                        // color: Theme.of(ctx).colorScheme.primary,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      );
}

class FrontView extends StatelessWidget {
  final AgentScreenState screenState;

  const FrontView({
    super.key,
    required this.screenState,
  });

  @override
  Widget build(BuildContext context) => components.MediaDeviceContextBuilder(
        builder: (context, roomCtx, mediaDeviceCtx) => Row(
          spacing: 20,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Flexible(
              flex: 2,
              fit: FlexFit.tight,
              child: AgentTrackView(),
            ),
            if (screenState == AgentScreenState.transcription && mediaDeviceCtx.cameraOpened)
              Flexible(
                fit: FlexFit.tight,
                child: AnimatedOpacity(
                  opacity: (screenState == AgentScreenState.transcription && mediaDeviceCtx.cameraOpened) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
                    child: components.ParticipantSelector(
                      filter: (identifier) => identifier.isVideo && identifier.isLocal,
                      builder: (context, identifier) => components.VideoTrackWidget(
                        fit: sdk.VideoViewFit.cover,
                        noTrackBuilder: (ctx) => Container(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class AgentScreen extends StatelessWidget {
  const AgentScreen({super.key});

  @override
  Widget build(BuildContext ctx) => Material(
        child: Selector<AppCtrl, AgentLayoutState>(
          selector: (ctx, appCtrl) => AgentLayoutState(
            isTranscriptionVisible: appCtrl.agentScreenState == AgentScreenState.transcription,
            isCameraVisible: appCtrl.isUserCameEnabled,
            isScreenshareVisible: appCtrl.isScreenshareEnabled,
          ),
          builder: (ctx, agentLayoutState, child) => AgentLayoutSwitcher(
            layoutState: agentLayoutState,
            // agentViewBuilder: (ctx) => AgentTrackView(),
            buildAgentView: (ctx) => const AgentTrackView(),
            buildCameraView: (ctx) => Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: components.MediaDeviceContextBuilder(
                builder: (context, roomCtx, mediaDeviceCtx) => components.ParticipantSelector(
                  filter: (identifier) => identifier.isVideo && identifier.isLocal,
                  builder: (context, identifier) => Stack(
                    children: [
                      components.VideoTrackWidget(
                        fit: sdk.VideoViewFit.cover,
                        noTrackBuilder: (ctx) => Container(),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: CameraToggleButton(
                          onTap: () => mediaDeviceCtx.toggleCameraPosition(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            buildScreenShareView: (ctx) => Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.3),
              ),
              child: const Text('Screenshare View'),
            ),
            transcriptionsBuilder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Live Transcript Header
                  const _TranscriptHeader(),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ctx.read<AppCtrl>().messageFocusNode.unfocus(),
                      child: Consumer<AppCtrl>(
                        builder: (context, appCtrl, _) {
                          final messages = appCtrl.allMessages;
                          if (messages.isEmpty) {
                            return _AgentListeningPlaceholder(canListen: appCtrl.session.agent.canListen);
                          }
                          return _MergedChatScrollView(
                            messages: messages,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.only(left: 16, right: 16, bottom: max(16, MediaQuery.of(ctx).viewInsets.bottom - 80)),
                    child: Selector<AppCtrl, bool>(
                      selector: (ctx, appCtx) => appCtx.isSendButtonEnabled,
                      builder: (ctx, isSendEnabled, child) => MessageBar(
                        focusNode: ctx.read<AppCtrl>().messageFocusNode,
                        isSendEnabled: isSendEnabled,
                        controller: ctx.read<AppCtrl>().messageCtrl,
                        onSendTap: () => ctx.read<AppCtrl>().sendMessage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}



/// Live Transcript header with recording indicator
class _TranscriptHeader extends StatelessWidget {
  const _TranscriptHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 18,
            color: Color(0xFF666666),
          ),
          const SizedBox(width: 8),
          const Text(
            'Live Transcript',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fiber_manual_record,
                  size: 8,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  'RECORDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentListeningPlaceholder extends StatelessWidget {
  const _AgentListeningPlaceholder({required this.canListen});

  final bool canListen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.graphic_eq, size: 32, color: colorScheme.primary.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(
            'Agent is listening',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (!canListen)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Start a conversation to see messages here.',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// Merged chat scroll view that displays all message types
class _MergedChatScrollView extends StatefulWidget {
  const _MergedChatScrollView({
    required this.messages,
    this.padding,
  });

  final List<UnifiedChatMessage> messages;
  final EdgeInsetsGeometry? padding;

  @override
  State<_MergedChatScrollView> createState() => _MergedChatScrollViewState();
}

class _MergedChatScrollViewState extends State<_MergedChatScrollView> {
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _autoScrollIfNeeded() {
    if (widget.messages.length == _lastMessageCount) return;
    _lastMessageCount = widget.messages.length;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _autoScrollIfNeeded();
    
    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: widget.padding,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[widget.messages.length - 1 - index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _UnifiedMessageBubble(message: message),
        );
      },
    );
  }
}

/// Message bubble that can render different sender types
class _UnifiedMessageBubble extends StatelessWidget {
  const _UnifiedMessageBubble({required this.message});

  final UnifiedChatMessage message;

  @override
  Widget build(BuildContext context) {
    final text = message.text.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    
    // Determine alignment and colors based on sender type
    final bool isUser = message.sender == MessageSender.user;
    final bool isPeer = message.sender == MessageSender.peer;
    
    Alignment alignment;
    Color background;
    Color foreground;
    
    // Light color scheme
    if (isUser) {
      alignment = Alignment.centerRight;
      background = const Color(0xFF2196F3); // Light blue
      foreground = Colors.white;
    } else if (isPeer) {
      alignment = Alignment.centerLeft;
      background = const Color(0xFFE8E8E8); // Light grey
      foreground = const Color(0xFF333333);
    } else {
      // Agent - light grey bubble
      alignment = Alignment.centerLeft;
      background = const Color(0xFFF0F0F0);
      foreground = const Color(0xFF333333);
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show sender name for peer messages
                if (isPeer && message.senderName != null) ...[
                  Text(
                    message.senderName!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
