import 'package:flutter/material.dart';

import 'agent_info_panel.dart';

@immutable
class AgentLayoutState {
  final bool isTranscriptionVisible;
  final bool isCameraVisible;
  final bool isScreenshareVisible;

  const AgentLayoutState({
    this.isTranscriptionVisible = false,
    this.isCameraVisible = false,
    this.isScreenshareVisible = false,
  });
}

extension AgentLayoutStateCopyExt on AgentLayoutState {
  AgentLayoutState copyWith({
    bool? isTranscriptionVisible,
    bool? isCameraVisible,
    bool? isScreenshareVisible,
  }) {
    return AgentLayoutState(
      isTranscriptionVisible: isTranscriptionVisible ?? this.isTranscriptionVisible,
      isCameraVisible: isCameraVisible ?? this.isCameraVisible,
      isScreenshareVisible: isScreenshareVisible ?? this.isScreenshareVisible,
    );
  }
}

/// Split-screen layout with agent info on left and transcript on right
class AgentLayoutSwitcher extends StatelessWidget {
  final AgentLayoutState layoutState;

  final Widget Function(BuildContext ctx) transcriptionsBuilder;
  final Widget Function(BuildContext ctx) buildAgentView;
  final Widget Function(BuildContext ctx) buildCameraView;
  final Widget Function(BuildContext ctx) buildScreenShareView;

  final Duration animationDuration;
  final Curve animationCurve;

  const AgentLayoutSwitcher({
    super.key,
    required this.layoutState,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationCurve = Curves.easeInOutSine,
    required this.transcriptionsBuilder,
    required this.buildAgentView,
    required this.buildCameraView,
    required this.buildScreenShareView,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left side: Agent Info Panel
        const Expanded(
          flex: 2,
          child: AgentInfoPanel(),
        ),
        // Right side: Transcript Panel
        Expanded(
          flex: 3,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFFF1F5F9), // Slate 100
                  Color(0xFFF8FAFC), // Slate 50
                ],
              ),
            ),
            child: transcriptionsBuilder(context),
          ),
        ),
      ],
    );
  }
}
