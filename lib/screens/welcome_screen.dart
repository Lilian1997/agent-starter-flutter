import 'package:flutter/material.dart';

import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:provider/provider.dart';
import '../controllers/app_ctrl.dart' as ctrl;
import '../widgets/audio_channel_toggle.dart';
import '../widgets/button.dart' as buttons;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Container(
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
              final isCompact = constraints.maxHeight < 500;
              final horizontalPadding = isCompact ? 12.0 : 16.0;
              final verticalPadding = isCompact ? 8.0 : 12.0;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(ctx, isCompact),
                    SizedBox(height: isCompact ? 12 : 16),

                    // Main Content
                    Expanded(
                      child: _buildHeroAction(ctx, isCompact),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx, bool isCompact) {
    final iconSize = isCompact ? 18.0 : 24.0;
    final titleFontSize = isCompact ? 16.0 : 20.0;

    return Row(
      children: [
        // Logo & Title
        Container(
          padding: EdgeInsets.all(isCompact ? 6 : 10),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.drive_eta, color: Colors.white, size: iconSize),
        ),
        SizedBox(width: isCompact ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IVI Assist',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'CONNECTED',
                style: TextStyle(
                  fontSize: isCompact ? 8 : 10,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Status badges
        _buildStatusIcon(Icons.signal_cellular_alt, const Color(0xFF10B981), '5G', isCompact),
        SizedBox(width: isCompact ? 4 : 8),
        _buildStatusIcon(Icons.bluetooth, const Color(0xFF3B82F6), 'BT', isCompact),
        SizedBox(width: isCompact ? 8 : 12),

        // Logout button
        _buildLogoutButton(ctx, isCompact),
      ],
    );
  }

  Widget _buildStatusIcon(IconData icon, Color color, String tooltip, bool isCompact) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 4 : 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: isCompact ? 12 : 16),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext ctx, bool isCompact) {
    return GestureDetector(
      onTap: () {
        Provider.of<ctrl.AppCtrl>(ctx, listen: false).logout();
      },
      child: Container(
        padding: EdgeInsets.all(isCompact ? 6 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Icon(Icons.logout, color: Colors.redAccent, size: isCompact ? 16 : 20),
      ),
    );
  }

  Widget _buildHeroAction(BuildContext ctx, bool isCompact) {
    return _GlassCard(
      isCompact: isCompact,
      child: Consumer2<ctrl.AppCtrl, sdk.Session>(
        builder: (ctx, appCtrl, session, child) {
          final isConnecting = appCtrl.isSessionStarting || session.connectionState != sdk.ConnectionState.disconnected;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Need Assistance on the Road?',
                style: TextStyle(
                  fontSize: isCompact ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isCompact ? 16 : 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 24 : 48),
                child: SizedBox(
                  width: double.infinity,
                  child: buttons.Button(
                    text: isConnecting ? 'Connecting...' : 'Start Call',
                    isProgressing: isConnecting,
                    onPressed: () => appCtrl.connect(),
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 16 : 24),
              // Audio Channel Control
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 24 : 48),
                child: const AudioChannelToggle(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final bool isCompact;

  const _GlassCard({
    required this.child, 
    this.height,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: child,
    );
  }
}


class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.6),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        ),
      ),
    );
  }
}
