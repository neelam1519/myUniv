import 'package:findany_flutter/Home.dart';
import 'package:findany_flutter/Login/login.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:in_app_update/in_app_update.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize EasyLoading
  runApp(MyApp());
  AuthWrapper().checkForUpdate();
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      title: 'Flutter Demo',
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  Utils utils = new Utils();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          if (snapshot.data != null) {
            return Home();
          } else {
            return Login();
          }
        }
      },
    );
  }

  Future<void> checkForUpdate() async {
    if (await utils.checkInternetConnection()) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          final appUpdateResult = await InAppUpdate.performImmediateUpdate();
          if (appUpdateResult == AppUpdateResult.success) {
            print('Updated successfully');
          } else {
            print('Unable to updated');
          }
        } else {
          print('No update available');
        }
      } catch (e) {
        print('Error checking for update: $e');
      }
    } else {
      print('No internet connection no update checked');
    }
  }
}
