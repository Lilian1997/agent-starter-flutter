import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_ctrl.dart';
import '../support/auth_repository.dart';
import '../widgets/button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 16 : 24,
                    vertical: isCompact ? 12 : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: EdgeInsets.all(isCompact ? 20 : 32),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            padding: EdgeInsets.all(isCompact ? 12 : 16),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.drive_eta,
                              color: Colors.white,
                              size: isCompact ? 32 : 40,
                            ),
                          ),
                          SizedBox(height: isCompact ? 16 : 24),
                          Text(
                            'IVI Assist',
                            style: TextStyle(
                              fontSize: isCompact ? 20 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: isCompact ? 8 : 12),
                          Text(
                            'Sign in to continue',
                            style: TextStyle(
                              fontSize: isCompact ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: isCompact ? 24 : 32),
                          Consumer<AppCtrl>(
                            builder: (context, appCtrl, child) {
                              return SizedBox(
                                width: double.infinity,
                                child: Button(
                                  text: 'Login',
                                  onPressed: () async {
                                    try {
                                      await appCtrl.login();
                                    } on AuthCancelledException {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Login cancelled')),
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint('Login error: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Login failed')),
                                        );
                                      }
                                    }
                                  },
                                  isProgressing: false,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
