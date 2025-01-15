import 'package:findany_flutter/Home.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Login extends StatelessWidget {
  Login({super.key});

  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'openid',
    ],
    serverClientId: '87807759596-u8abgv3eprlfa30cvfmijeu31olmv9qb.apps.googleusercontent.com',
  );

  LoadingDialog loadingDialog = LoadingDialog();

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      loadingDialog.showDefaultLoading("Signing you in...");
      print("Displaying loading dialog...");

      print("Initiating Google Sign-In...");
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In was canceled by the user.')),
        );
        print("Google Sign-In was canceled by the user.");
        Navigator.of(context).pop();
        return;
      }
      print("Google Sign-In successful. User info: ${googleUser.displayName}, ${googleUser.email}");

      print("Fetching authentication tokens...");
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print("Authentication tokens are null. AccessToken: ${googleAuth.accessToken}, IdToken: ${googleAuth.idToken}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed.')),
        );
        return;
      }
      print("Authentication tokens fetched successfully. AccessToken: ${googleAuth.accessToken}");

      print("Creating Firebase credential...");
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("Signing in with Firebase...");
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        print("Firebase sign-in successful. User: ${user.displayName}, Email: ${user.email}");
        if (user.email != null && user.email!.endsWith('@klu.ac.in')) {
          print("User email is valid: ${user.email}");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User Logged in Sucessfully')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Home(),
            ),
          );
          // Navigate to the home page or perform other actions
        } else {
          print("Invalid email domain. User email: ${user.email}");
          await googleSignIn.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Use your university email to log in.')),
          );
        }
      } else {
        print("Firebase sign-in returned null user.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in failed.')),
        );
      }
    } catch (e, stackTrace) {
      print("Error during sign-in: $e");
      print("Stack trace: $stackTrace");
      Navigator.of(context).pop(); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    }

    loadingDialog.dismiss();
  }


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
              SignInButton(
                Buttons.Google,
                text: "Sign in with Google",
                onPressed: () => signInWithGoogle(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
