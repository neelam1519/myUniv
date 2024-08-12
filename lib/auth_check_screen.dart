import 'package:findany_flutter/provider/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Home.dart';
import 'Login/login.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProviderStart(),
      child: Consumer<AuthProviderStart>(
        builder: (context, authProvider, child) {
          return StreamBuilder<User?>(
            stream: authProvider.authStateChanges,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                EasyLoading.show(status: 'Loading...');
                return const Center(child: CircularProgressIndicator());
              } else {
                EasyLoading.dismiss();
                return snapshot.hasData ? const Home() : const Login();
              }
            },
          );
        },
      ),
    );
  }
}