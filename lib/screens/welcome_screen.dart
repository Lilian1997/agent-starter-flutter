import 'package:flutter/material.dart';

import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:provider/provider.dart';
import '../controllers/app_ctrl.dart' as ctrl;
import '../widgets/button.dart' as buttons;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Stack(
        children: [
          // Background (Light Theme Gradient)
          Container(
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
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Fixed Header (always visible, not scrolling)
                  _buildHeader(ctx),
                  const SizedBox(height: 24),

                  // Scrollable Main Content
                  Expanded(
                    child: Row(
                      children: [
                        // Left Column (Hero Action)
                        Expanded(
                          flex: 3,
                          child: _buildHeroAction(ctx),
                        ),
                        const SizedBox(width: 8),

                        // Right Column (Status & Info)
                        // Expanded(
                        //   flex: 2,
                        //   child: Column(
                        //     children: [
                        //       _buildAudioStatus(),
                        //       const SizedBox(height: 8),
                        //       Expanded(child: _buildVehicleStatus()),
                        //     ],
                        //   ),
                        // ),
                      ],
                    ),
                    // LayoutBuilder(
                    //   builder: (context, constraints) {
                    //     final screenHeight = constraints.maxHeight;
                    //     final isCompact = screenHeight < 400;

                    //     if (isCompact) {
                    //       return SingleChildScrollView(
                    //         child: _buildCompactLayout(ctx),
                    //       );
                    //     } else {
                    //       // Desktop two-column layout
                    //       return _buildDesktopLayout(ctx);
                    //     }
                    //   },

                    // ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx) {
    return Row(
      children: [
        // Logo & Title
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.drive_eta, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IVI Assist',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'CONNECTED',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey[600], letterSpacing: 1.2, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // Status badges (compact icon-only style)
        _buildStatusIcon(Icons.signal_cellular_alt, const Color(0xFF10B981), '5G'),
        const SizedBox(width: 8),
        _buildStatusIcon(Icons.bluetooth, const Color(0xFF3B82F6), 'BT'),
        const SizedBox(width: 12),

        // Logout button (always visible)
        _buildLogoutButton(ctx),
      ],
    );
  }

  /// Compact status icon with tooltip
  Widget _buildStatusIcon(IconData icon, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext ctx) {
    return GestureDetector(
      onTap: () {
        Provider.of<ctrl.AppCtrl>(ctx, listen: false).logout();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
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
        child: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
      ),
    );
  }

  Widget _buildHeroAction(BuildContext ctx) {
    return _GlassCard(
      child: Consumer2<ctrl.AppCtrl, sdk.Session>(
        builder: (ctx, appCtrl, session, child) {
          final isConnecting = appCtrl.isSessionStarting || session.connectionState != sdk.ConnectionState.disconnected;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text(
                'Need Assistance on the Road?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: SizedBox(
                  // Wrap in SizedBox for width if Button doesn't support width
                  width: double.infinity,
                  child: buttons.Button(
                    text: isConnecting ? 'Connecting...' : 'Start Call',
                    // icon: Icons.support_agent, // Ensure your Button widget supports icon if you want it
                    isProgressing: isConnecting,
                    onPressed: () => appCtrl.connect(),
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
  }

  Widget _buildAudioStatus() {
    return _GlassCard(
      height: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Audio Routing',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Flexible(
                child: Text(
                  'CHANGE',
                  style: TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Visual Mockup of Balance
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100], // Colors.black26 -> Light Grey
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Left', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(height: 4, color: Colors.grey[300]), // Grey 800 -> Grey 300
                      Container(
                        height: 4,
                        width: 100,
                        margin: const EdgeInsets.only(left: 40), // Shifted right for "Driver"
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Text('Right', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Center(
              child: Text('Driver Side Focus', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildVehicleStatus() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle ID',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Model', 'Model X-1'),
          const Divider(color: Colors.black12), // Colors.white10 -> Black12
          _buildInfoRow('VIN End', '...8492'),
          const Divider(color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAST SERVICE', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                  const SizedBox(height: 4),
                  const Text('Oct 24, 2023', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                ],
              ),
              const Icon(Icons.check_circle, color: Color(0xFF10B981)), // AppTheme.success
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double? height;

  const _GlassCard({required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Glassy white
        borderRadius: BorderRadius.circular(24),
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
