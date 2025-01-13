import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Firebase/firestore.dart';
import '../Home.dart';
import '../utils/LoadingDialog.dart';
import '../utils/sharedpreferences.dart';
import '../utils/utils.dart';

class LoginProvider with ChangeNotifier {
  final Utils utils = Utils();
  final LoadingDialog loadingDialog = LoadingDialog();
  final SharedPreferences sharedPreferences = SharedPreferences();
  final FireStoreService fireStoreService = FireStoreService();


  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile',
      'openid',
    ],
  );

  Future<UserCredential?> signInWithGoogle() async {
    loadingDialog.showDefaultLoading("Signing in...");
    try {
      print("google signin data ${googleSignIn.clientId} ${googleSignIn.serverClientId} ${googleSignIn.scopes}");

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Sign-in aborted by user.');
        loadingDialog.dismiss();
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Access token or ID token is null.');
        loadingDialog.dismiss();
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Credentials: $credential');
      loadingDialog.dismiss();
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e, stackTrace) {
      print('Error signing in with Google: $e');
      print('Stack trace: $stackTrace');
      utils.showToastMessage('Login Error. Please try again later.');
      loadingDialog.dismiss();
      return null;
    }
  }


// Future<void> handleGoogleSignIn(BuildContext context) async {
  //   if (await googleSignIn.isSignedIn()) {
  //     print("not disconnected");
  //     await googleSignIn.disconnect();
  //     await googleSignIn.signOut();
  //   }else{
  //     print('Disconnected');
  //   }
  //
  //   try {
  //     print('Attempting to show loading dialog...');
  //     loadingDialog.showDefaultLoading('Signing In...');
  //     print('Loading dialog shown successfully.');
  //
  //     print('Initiating Google Sign-In...');
  //     final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
  //
  //     if (googleSignInAccount != null) {
  //       print('Google Sign-In successful. Account details:');
  //       print('Display Name: ${googleSignInAccount.displayName}');
  //       print('Email: ${googleSignInAccount.email}');
  //       print('ID: ${googleSignInAccount.id}');
  //
  //       print('Proceeding to Firebase sign-in...');
  //       await firebaseSignIn(googleSignInAccount, context);
  //       print('Firebase sign-in process completed.');
  //     } else {
  //       print('Google Sign-In canceled by user.');
  //       loadingDialog.dismiss();
  //     }
  //   } catch (error, stackTrace) {
  //     print('Error occurred during the sign-in process: $error');
  //     print('Stack Trace: $stackTrace');
  //
  //     loadingDialog.dismiss();
  //     utils.showToastMessage('Error occurred while logging in: $error');
  //
  //     print('Attempting to sign out due to error...');
  //     await signOut();
  //     print('Sign-out process completed after error.');
  //   }
  //
  // }
  //
  // Future<void> firebaseSignIn(GoogleSignInAccount googleSignInAccount, BuildContext context) async {
  //   try {
  //     loadingDialog.showDefaultLoading('Singing...');
  //
  //     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  //
  //     if (googleUser == null) {
  //       print('Google Sign-In canceled or failed.');
  //       throw Exception('Google sign-in returned null account.');
  //     }
  //
  //     final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
  //
  //     if (googleAuth == null) {
  //       print('Failed to retrieve authentication details from Google.');
  //       throw Exception('Google authentication returned null.');
  //     }
  //
  //     final AuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //     final UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(credential);
  //
  //     final User? user = authResult.user;
  //
  //     if (user != null && context.mounted) {
  //       print('Firebase sign-in successful. User ID: ${user.uid}, Email: ${user.email}');
  //
  //       final String? email = user.email;
  //
  //       if (email != null && email.endsWith('@klu.ac.in')) {
  //         print('User email is valid (${email}). Checking if user exists in Firestore...');
  //
  //         final DocumentReference userDoc = FirebaseFirestore.instance.collection('UserDetails').doc(user.uid);
  //         final DocumentSnapshot userSnapshot = await userDoc.get();
  //
  //         if (userSnapshot.exists) {
  //           print('User already exists. Navigating to Home...');
  //         } else {
  //           print('New user detected. Storing required data...');
  //           //await storeRequiredData(context);
  //         }
  //       } else {
  //         print('Invalid email domain. User email: $email');
  //         await signOut();
  //         loadingDialog.showInfoMessage("Login with KALASALINGAM EMAIL ONLY");
  //       }
  //     } else {
  //       print('User is null after Firebase sign-in.');
  //       await signOut();
  //       loadingDialog.dismiss();
  //     }
  //   } catch (error, stackTrace) {
  //     print('Error during Firebase Sign-In: $error');
  //     print('Stack Trace: $stackTrace');
  //     utils.showToastMessage('Error occurred while logging in. Please try again.');
  //     await signOut();
  //     loadingDialog.dismiss();
  //   }
  // }
  //
  // Future<void> signOut() async {
  //   try {
  //     if (await googleSignIn.isSignedIn()) {
  //       await googleSignIn.disconnect();
  //     }
  //   } catch (e) {
  //     print('Error disconnecting from Google: $e');
  //   } finally {
  //     await googleSignIn.signOut();
  //     await FirebaseAuth.instance.signOut();
  //   }
  // }
}