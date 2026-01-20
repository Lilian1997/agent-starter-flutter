import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_ctrl.dart';
import '../widgets/button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Consumer<AppCtrl>(
                builder: (context, appCtrl, child) {
                  return Button(
                    text: 'Login',
                    onPressed: () => appCtrl.login(),
                    isProgressing: false, // We can add loading state later if needed
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
