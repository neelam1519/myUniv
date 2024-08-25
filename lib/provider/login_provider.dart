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
  Utils utils = Utils();
  LoadingDialog loadingDialog = LoadingDialog();
  SharedPreferences sharedPreferences = SharedPreferences();
  FireStoreService fireStoreService = FireStoreService();

  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile',
      'openid'
    ],
  );

  Future<void> handleGoogleSignIn(BuildContext context) async {
    try {
      loadingDialog.showDefaultLoading('Signing In...');
      GoogleSignInAccount? googleSignInAccount = await mobileGoogleSignIn();

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

  Future<GoogleSignInAccount?> mobileGoogleSignIn() async {
    GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
    googleSignInAccount ??= await googleSignIn.signIn();
    return googleSignInAccount;
  }

  Future<void> firebaseSignIn(GoogleSignInAccount googleSignInAccount, BuildContext context) async {
    try {
      final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = authResult.user;

      if (user != null && context.mounted) {
        final String? email = user.email;

        if (email != null && email.endsWith('@klu.ac.in')) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
          await storeRequiredData(context);
        } else {
          await signOut();
          loadingDialog.showInfoMessage("Login with KALASALINGAM EMAIL ONLY");
        }
      } else {
        await signOut();
        loadingDialog.dismiss();
      }
    } catch (error) {
      print('Error during Firebase Sign-In: $error');
      utils.showToastMessage('Error occurred while logging in login again');
      await signOut();
      loadingDialog.dismiss();
    }
  }

  Future<void> storeRequiredData(BuildContext context) async {
    try {
      String email = await utils.getCurrentUserEmail() ?? " ";
      String displayName = await utils.getCurrentUserDisplayName() ?? " ";
      String imageUrl = await utils.getCurrentUserProfileImage() ?? " ";
      String token = await utils.getToken() ?? " ";

      print('Login Token: $token');

      String name = utils.removeTextAfterFirstNumber(displayName);
      String regNo = utils.removeEmailDomain(email);

      Map<String, String> data = {
        'Email': email,
        'Name': name,
        'ProfileImageURL': imageUrl,
        'Registration Number': regNo,
      };
      print('Login Details: $data');

      String? currentUserUID = await utils.getCurrentUserUID();

      DocumentReference documentReference = FirebaseFirestore.instance.doc('/UserDetails/$currentUserUID');
      fireStoreService.uploadMapDataToFirestore(data, documentReference);
      sharedPreferences.storeMapValuesInSecureStorage(data);

      DocumentReference tokenRef = FirebaseFirestore.instance.doc('Tokens/Tokens');
      await fireStoreService.uploadMapDataToFirestore({regNo: token}, tokenRef);
      loadingDialog.dismiss();
    } catch (error) {
      print('Error storing data: $error');
      utils.showToastMessage('Error occurred while logging in: $error');
      print('Login Error: $error');
      await signOut();
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      await googleSignIn.disconnect();
    } catch (e) {
      print('Error disconnecting from Google: $e');
    }
    await googleSignIn.signOut();
  }
}
