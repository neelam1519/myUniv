import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Home.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Utils utils = Utils();
  LoadingDialog loadingDialog = LoadingDialog();
  SharedPreferences sharedPreferences = SharedPreferences();
  FireStoreService fireStoreService = FireStoreService();

  final GoogleSignIn googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Hero(
                tag: 'app-logo',
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 120.0,
                ),
              ),
              SizedBox(height: 40.0),
              Text(
                'Welcome to FindAny',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
              SizedBox(height: 20.0),
              Card(
                elevation: 5.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.grey[700],
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
                            await _handleGoogleSignIn(context);
                          } else {
                            utils.showToastMessage('Check your internet connection', context);
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                        elevation: 5.0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    if(!await utils.checkInternetConnection()){
      utils.showToastMessage('Connect to the Internet', context);
      return;
    }
    print('Handle Google Sign-In');
    try {
      loadingDialog.showDefaultLoading('Signing In...');

      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

        print('Access Token: ${googleSignInAuthentication.accessToken}');
        print('ID Token: ${googleSignInAuthentication.idToken}');

        if (googleSignInAuthentication.accessToken == null || googleSignInAuthentication.idToken == null) {
          throw Exception('Google Sign-In authentication tokens are null');
        }

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(credential);
        final User? user = authResult.user;

        if (user != null && mounted) {
          final String? email = user.email;
          if (email != null && email.endsWith('@klu.ac.in')) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
            await storeRequiredData();
          } else {
            await utils.signOut();
            loadingDialog.showError('Please sign in with a valid KLU email.');
          }
        } else {
          print('User is null after signing in.');
          await utils.signOut();
          loadingDialog.dismiss();
        }
      } else {
        print('Google Sign in canceled.');
        loadingDialog.dismiss();
      }
    } catch (error) {
      loadingDialog.dismiss();
      utils.showToastMessage('Error occurred while login', context);
      print('Error signing in with Google: $error');
      await utils.signOut();
    }
  }

  Future<void> storeRequiredData() async {
    try {
      String email = await utils.getCurrentUserEmail() ?? " ";
      String displayName = await utils.getCurrentUserDisplayName() ?? " ";
      String imageUrl = await utils.getCurrentUserProfileImage() ?? " ";
      String token = await utils.getToken() ?? " ";

      print('Login Token : $token');

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
      utils.showToastMessage('Error occurred while login  $error', context);
      print('Login Error2: $error');
      utils.signOut();
    }
  }
  @override
  void dispose() {
    loadingDialog.dismiss();
    super.dispose();
  }
}
