import 'package:findany_flutter/main.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Login extends StatefulWidget {

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Utils utils = new Utils();
  LoadingDialog loadingDialog = new LoadingDialog();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () async {
            await _handleGoogleSignIn(); // Corrected method name
          },
          child: Image.asset(
            'assets/images/google-signin-button.png',
            height: 48.0,
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      loadingDialog.showDefaultLoading('Signing In...');
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential authResult =
        await FirebaseAuth.instance.signInWithCredential(credential);
        final User? user = authResult.user;
        if (user != null && mounted) { // Check if the widget is still mounted
          await storeRequiredData();
          EasyLoading.dismiss().then((value) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp()));
          });
        }
        print("LOGIN UID: ${utils.getCurrentUserUID()}");
      } else {
        // User canceled the sign-in
        print('Google Sign in canceled.');
      }
    } catch (error) {
      EasyLoading.dismiss();
      print('Error signing in with Google: $error');
    }
  }


  Future<void> storeRequiredData() async {
    SharedPreferences sharedPreferences = new SharedPreferences();
    String email = await utils.getCurrentUserEmail() ?? '';
    String name = await utils.getCurrentUserDisplayName() ?? '';
    String imageUrl = await getCurrentUserProfileImage() ?? '';

    Map<String, String> data = {'Email': email, 'Name': name, 'ProfileImageURL': imageUrl};

    sharedPreferences.storeMapValuesInSecureStorage(data);
  }

  Future<String?> getCurrentUserProfileImage() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.photoURL != null) {
        return user.photoURL;
      } else {
        return null; // No profile image set or user not signed in
      }
    } catch (e) {
      print('Error getting user profile image URL: $e');
      return null;
    }
  }


}

