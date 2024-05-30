import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Home.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Utils utils = new Utils();
  LoadingDialog loadingDialog = new LoadingDialog();
  SharedPreferences sharedPreferences = new SharedPreferences();
  FireStoreService fireStoreService = new FireStoreService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/logo.png', // Add the path to your app logo here
                height: 120.0,
              ),
              SizedBox(height: 40.0),
              Text(
                'Welcome to FindAny',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.0),
              SignInButton(
                Buttons.Google,
                text: "Sign in with Google",
                onPressed: () async {
                  bool internet = await utils.checkInternetConnection();
                  print('Internet Connection: $internet');
                  if (internet) {
                    await _handleGoogleSignIn();
                  } else {
                    utils.showToastMessage('Check your internet connection', context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    print('Handle google sign');
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

        if (user != null && mounted) {
          if (user.email != null && user.email!.endsWith('@klu.ac.in')) {
            await storeRequiredData().then((value) {
              print('Login Value: $value');
              if (value != null) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
              } else {
                utils.showToastMessage('Error occurred unable to login', context);
              }
            });
          } else {
            await FirebaseAuth.instance.signOut();
            await _googleSignIn.disconnect();
            loadingDialog.showError('Please sign in with a valid KLU email.');
          }
        }
        print("LOGIN UID: ${utils.getCurrentUserUID()}");
      } else {
        print('Google Sign in canceled.');
        loadingDialog.dismiss();
      }
    } catch (error) {
      loadingDialog.dismiss();
      utils.showToastMessage('Error occurred while login', context);
      utils.signOut();
      print('Error signing in with Google: $error');
    }
  }

  Future<Map<String, String>?> storeRequiredData() async {
    String email = await utils.getCurrentUserEmail() ?? '';
    String displayName = await utils.getCurrentUserDisplayName() ?? '';
    String name = utils.removeTextAfterFirstNumber(displayName);
    String imageUrl = await getCurrentUserProfileImage() ?? '';
    String regNo = utils.removeEmailDomain(email);
    String? token = await utils.getToken();

    Map<String, String> data = {
      'Email': email,
      'Name': name,
      'ProfileImageURL': imageUrl,
      'Registration Number': regNo,
    };
    print('Login Details: $data');
    DocumentReference documentReference = FirebaseFirestore.instance.doc('/UserDetails/${utils.getCurrentUserUID()}');

    try {
      DocumentSnapshot documentSnapshot = await documentReference.get();
      if (documentSnapshot.exists) {
        print('Document exists');
        Map<String, dynamic>? retrievedData = await fireStoreService.getDocumentDetails(documentReference);
        print("Retrieved Data: $retrievedData");
        if (retrievedData != null && retrievedData.containsKey('ProfileImageURL')) {
          String profileImageURL = retrievedData['ProfileImageURL'];
          print('Image Link: $profileImageURL');
          if (profileImageURL.startsWith('https://firebasestorage.googleapis.com')) {
            data['ProfileImageURL'] = retrievedData['ProfileImageURL'];
            print('Profile image URL updated');
          } else {
            print('Profile image URL is a current email profile link, not updating');
          }
        } else {
          print('ProfileImageURL field not found in retrieved data');
        }
      } else {
        print('Document does not exist');
      }
    } catch (error) {
      print('Error: $error');
      utils.showToastMessage('Error occurred while login', context);
      utils.signOut();
    }
    try {
      DocumentReference tokenRef = FirebaseFirestore.instance.doc('Tokens/Tokens');
      await fireStoreService.uploadMapDataToFirestore({regNo: token}, tokenRef);
      DocumentReference userRef = FirebaseFirestore.instance.doc('UserDetails/${utils.getCurrentUserUID()}');
      await sharedPreferences.storeMapValuesInSecureStorage(data);
      await fireStoreService.uploadMapDataToFirestore(data, userRef);
      loadingDialog.dismiss();
      if (mounted) {
        return data;
      }
    } catch (error) {
      print('Error storing data: $error');
      utils.showToastMessage('Error occurred while login', context);
      utils.signOut();
    }
    return null;
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
