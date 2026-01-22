import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sficon/flutter_sficon.dart' as sf;
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:provider/provider.dart';

import '../controllers/app_ctrl.dart';
import '../support/agent_selector.dart';
import '../ui/color_pallette.dart';

/// Left panel showing agent information in split-screen layout
class AgentInfoPanel extends StatelessWidget {
  const AgentInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC), // Slate 50
            Color(0xFFE2E8F0), // Slate 200
            Color(0xFFF1F5F9), // Slate 100
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive sizing based on available height
            final isCompact = constraints.maxHeight < 500;
            final avatarSize = isCompact ? 56.0 : 80.0;
            final timerFontSize = isCompact ? 16.0 : 28.0;
            final spacing = isCompact ? 12.0 : 20.0;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 16 : 24,
                    vertical: isCompact ? 12 : 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: spacing),
                      // Agent Avatar
                      _AgentAvatar(size: avatarSize),
                      SizedBox(height: isCompact ? 10 : 16),
                      // Agent Name & Title
                      _AgentNameTitle(isCompact: isCompact),
                      SizedBox(height: isCompact ? 16 : 32),
                      // Call Timer
                      _CallTimer(fontSize: timerFontSize),
                      SizedBox(height: isCompact ? 12 : 24),
                      // Audio Waveform
                      _AudioWaveformIndicator(isCompact: isCompact),
                      SizedBox(height: spacing * 2),
                      // Control Buttons
                      _ControlButtons(isCompact: isCompact),
                      SizedBox(height: isCompact ? 12 : 16),
                      // End Call Button
                      const _EndCallButton(),
                      SizedBox(height: isCompact ? 12 : 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Gradient circular avatar for the agent
class _AgentAvatar extends StatelessWidget {
  const _AgentAvatar({this.size = 80.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade300,
            Colors.blueAccent.shade100,
            Colors.blue.shade400,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.3),
            blurRadius: size * 0.15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.support_agent,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }
}

/// Agent name and title display
class _AgentNameTitle extends StatelessWidget {
  const _AgentNameTitle({this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = LKColorPaletteLight();

    return Column(
      children: [
        Text(
          'AI Assistant',
          style: (isCompact ? textTheme.titleMedium : textTheme.titleLarge)?.copyWith(
            fontWeight: FontWeight.w600,
            color: palette.fg1,
          ),
        ),
      ],
    );
  }
}

/// Call duration timer
class _CallTimer extends StatefulWidget {
  const _CallTimer({this.fontSize = 48.0});

  final double fontSize;

  @override
  State<_CallTimer> createState() => _CallTimerState();
}

class _CallTimerState extends State<_CallTimer> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final palette = LKColorPaletteLight();

    return Text(
      _formatDuration(_elapsed),
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w300,
        color: palette.fg1,
        letterSpacing: widget.fontSize > 40 ? 2 : 1,
      ),
    );
  }
}

/// Audio waveform visualization with label
class _AudioWaveformIndicator extends StatelessWidget {
  const _AudioWaveformIndicator({this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final waveformHeight = isCompact ? 28.0 : 40.0;
    final waveformWidth = isCompact ? 90.0 : 120.0;

    return Column(
      children: [
        AgentParticipantSelector(
          builder: (ctx, agentParticipant) {
            if (agentParticipant == null) {
              return SizedBox(height: waveformHeight);
            }
            return SizedBox(
              height: waveformHeight,
              width: waveformWidth,
              child: components.ParticipantSelector(
                filter: (identifier) => !identifier.isLocal && identifier.isAudio,
                builder: (context, identifier) => components.AudioVisualizerWidget(
                  options: components.AudioVisualizerWidgetOptions(
                    barCount: isCompact ? 5 : 7,
                    spacing: isCompact ? 3 : 4,
                    width: isCompact ? 6 : 8,
                    minHeight: isCompact ? 6 : 8,
                    maxHeight: waveformHeight,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Speaker and mute control buttons
class _ControlButtons extends StatelessWidget {
  const _ControlButtons({this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return components.MediaDeviceContextBuilder(
      builder: (context, roomCtx, mediaDeviceCtx) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Speaker button
          _ControlButton(
            icon: sf.SFIcons.sf_speaker_wave_2_fill,
            label: 'Speaker',
            isActive: true,
            isCompact: isCompact,
            onTap: () {
              // Toggle speaker
            },
          ),
          SizedBox(width: isCompact ? 20 : 32),
          // Mute button
          _ControlButton(
            icon: mediaDeviceCtx.microphoneOpened ? sf.SFIcons.sf_microphone_fill : sf.SFIcons.sf_microphone_slash_fill,
            label: 'Mute',
            isActive: !mediaDeviceCtx.microphoneOpened,
            isCompact: isCompact,
            onTap: () {
              mediaDeviceCtx.microphoneOpened ? mediaDeviceCtx.disableMicrophone() : mediaDeviceCtx.enableMicrophone();
            },
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isCompact;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = LKColorPaletteLight();
    final buttonSize = isCompact ? 44.0 : 56.0;
    final iconSize = isCompact ? 18.0 : 22.0;
    final labelFontSize = isCompact ? 10.0 : 12.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? palette.bg3 : palette.bg2,
              border: Border.all(
                color: palette.separator2,
                width: 1,
              ),
            ),
            child: Center(
              child: sf.SFIcon(
                icon,
                fontSize: iconSize,
                color: palette.fg2,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              color: palette.fg3,
            ),
          ),
        ],
      ),
    );
  }
}

/// End call button
class _EndCallButton extends StatelessWidget {
  const _EndCallButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.read<AppCtrl>().disconnect(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const sf.SFIcon(
          sf.SFIcons.sf_phone_down_fill,
          fontSize: 18,
          color: Colors.white,
        ),
        label: const Text(
          'End Call',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
