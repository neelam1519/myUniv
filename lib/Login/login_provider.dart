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

  Future<void> handleGoogleSignIn(BuildContext context) async {
    if (await googleSignIn.isSignedIn()) {
      print("not disconnected");
      await googleSignIn.disconnect();
      await googleSignIn.signOut();
    }else{
      print('Disconnected');
    }

    try {
      loadingDialog.showDefaultLoading('Signing In...');

      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        if (context.mounted) {
          await firebaseSignIn(googleSignInAccount, context);
        }
      } else {
        print('Google Sign-In canceled.');
        loadingDialog.dismiss();
      }
    } catch (error) {
      loadingDialog.dismiss();
      utils.showToastMessage('Error occurred while logging in: $error');
      print('Error signing in with Google: $error');
      await signOut();
    }
  }

  Future<void> firebaseSignIn(GoogleSignInAccount googleSignInAccount, BuildContext context) async {
    try {
      print('Starting Google Sign-In process...');

      // Get Google authentication details
      GoogleSignInAuthentication? googleAuth = await (await GoogleSignIn(scopes: ["profile", "email"]).signIn())?.authentication;
      print('Google authentication successful. Access Token: ${googleAuth!.accessToken}, ID Token: ${googleAuth.idToken}');

      // Create a credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = authResult.user;

      if (user != null && context.mounted) {
        print('Firebase sign-in successful. User ID: ${user.uid}, Email: ${user.email}');

        final String? email = user.email;

        if (email != null && email.endsWith('@klu.ac.in')) {
          print('User  email is valid. Navigating to Home...');
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
          await storeRequiredData(context);
        } else {
          print('Invalid email domain. User email: $email');
          await signOut();
          loadingDialog.showInfoMessage("Login with KALASALINGAM EMAIL ONLY");
        }
      } else {
        print('User  is null after Firebase sign-in.');
        await signOut();
        loadingDialog.dismiss();
      }
    } catch (error) {
      print('Error during Firebase Sign-In: $error');
      utils.showToastMessage('Error occurred while logging in. Please try again.');
      await signOut();
      loadingDialog.dismiss();
    }
  }

  Future<void> storeRequiredData(BuildContext context) async {
    try {
      final String email = await utils.getCurrentUserEmail() ?? " ";
      final String displayName = await utils.getCurrentUserDisplayName() ?? " ";
      final String imageUrl = await utils.getCurrentUserProfileImage() ?? " ";
      final String token = await utils.getToken() ?? " ";

      print('Login Token: $token');

      final String name = utils.removeTextAfterFirstNumber(displayName);
      final String regNo = utils.removeEmailDomain(email);

      final Map<String, String> data = {
        'Email': email,
        'Name': name,
        'ProfileImageURL': imageUrl,
        'Registration Number': regNo,
      };

      print('Login Details: $data');

      final String? currentUserUID = await utils.getCurrentUserUID();
      final DocumentReference userDoc = FirebaseFirestore.instance.doc('/UserDetails/$currentUserUID');

      await fireStoreService.uploadMapDataToFirestore(data, userDoc);
      sharedPreferences.storeMapValuesInSecureStorage(data);

      final DocumentReference tokenRef = FirebaseFirestore.instance.doc('Tokens/Tokens');
      await fireStoreService.uploadMapDataToFirestore({regNo: token}, tokenRef);
      loadingDialog.dismiss();
    } catch (error) {
      print('Error storing data: $error');
      utils.showToastMessage('Error occurred while storing data: $error');
      await signOut();
    }
  }

  Future<void> signOut() async {
    try {
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
      }
    } catch (e) {
      print('Error disconnecting from Google: $e');
    } finally {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    }
  }
}