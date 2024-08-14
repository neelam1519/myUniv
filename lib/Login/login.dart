import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:provider/provider.dart';

import '../provider/login_provider.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                'Welcome to FindAny',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20.0),
              Consumer<LoginProvider>(
                builder: (context, loginProvider, child) {
                  return SignInButton(
                    Buttons.Google,
                    text: "Sign in with Google",
                    onPressed: () async {
                      bool internet = await loginProvider.utils.checkInternetConnection();
                      if (kDebugMode) {
                        print('Internet Connection: $internet');
                      }
                      if (internet) {
                        if (context.mounted) {
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