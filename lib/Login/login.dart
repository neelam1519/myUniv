import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:provider/provider.dart';

import 'login_provider.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(fontSize: 20, letterSpacing: 1.5, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.green[400],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/logo.png',
                height: 120.0,
              ),
              const SizedBox(height: 40.0),
              const Text(
                'Welcome to myUniv',
                style: TextStyle(
                  fontSize: 26.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Only Kalasalingam University students can log in using their university email.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 40.0),
              Consumer<LoginProvider>(
                builder: (context, loginProvider, child) {
                  return SignInButton(
                    Buttons.Google,
                    text: "Sign in with Google",
                    onPressed: () async {
                      bool internet = await loginProvider.utils.checkInternetConnection();
                      if (internet) {
                        if (context.mounted) {
                          print("User is signing in...");
                          await loginProvider.handleGoogleSignIn(context);
                        }
                      } else {
                        loginProvider.utils.showToastMessage('Check your internet connection');
                      }
                    },
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
