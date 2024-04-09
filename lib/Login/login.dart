import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Home.dart';
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
  SharedPreferences sharedPreferences = new SharedPreferences();
  FireStoreService fireStoreService = new FireStoreService();

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
            bool internet = await utils.checkInternetConnection();
            print('Internet Connection: $internet');
            if(internet){
              await _handleGoogleSignIn();
            }else{
              utils.showToastMessage('Check your internet connection', context);
            }
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

        if (user != null && mounted) { // Check if the widget is still mounted
          if (user.email != null && user.email!.endsWith('@klu.ac.in')) {
            DocumentReference documentReference = FirebaseFirestore.instance.doc('/UserDetails/${utils.getCurrentUserUID()}');

            Map<String,String> data= await storeRequiredData();
            documentReference.get().then((DocumentSnapshot documentSnapshot) async {
              if (documentSnapshot.exists) {
                print('Document exists');
                Map<String, dynamic>? retrievedData = await fireStoreService.getDocumentDetails(documentReference);
                print("Retrived Data: $retrievedData");
                // Check if the retrieved data contains the ProfileImageURL field
                if (retrievedData != null && retrievedData.containsKey('ProfileImageURL')) {
                  String profileImageURL = retrievedData['ProfileImageURL'];
                  print('Image Link: $profileImageURL');

                  // Check if the profile image URL is a Firebase storage link or a current email profile link
                  if (profileImageURL.startsWith('https://firebasestorage.googleapis.com')) {
                    // Update the data with the new profile image URL
                    data['ProfileImageURL'] = retrievedData['ProfileImageURL'];
                    print('Profile image URL updated');
                  } else {
                    // Profile image URL is a current email profile link, don't change it
                    print('Profile image URL is a current email profile link, not updating');
                  }
                } else {
                  print('ProfileImageURL field not found in retrieved data');
                }
              } else {
                print('Document does not exist');
              }
            }).catchError((error) {
              print('Error: $error');
            }).then((value) async {
              DocumentReference userRef = FirebaseFirestore.instance.doc('UserDetails/${utils.getCurrentUserUID()}');
              print('SharedPreferences Values: ${data.toString()}');
              await sharedPreferences.storeMapValuesInSecureStorage(data).then((value) {
                fireStoreService.uploadMapDataToFirestore(data, userRef).then((value) {
                  EasyLoading.dismiss().then((value) {
                    if(mounted){
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
                    }
                  });
                });
              });
            });
          } else {
            // Sign out the user if the email domain is not "@klu.ac.in"
            await FirebaseAuth.instance.signOut();
            await _googleSignIn.disconnect(); // Disconnect the user
            EasyLoading.showError('Please sign in with a valid KLU email.');
          }
        }
        print("LOGIN UID: ${utils.getCurrentUserUID()}");
      } else {
        // User canceled the sign-in
        print('Google Sign in canceled.');
        EasyLoading.dismiss();
      }
    } catch (error) {
      EasyLoading.dismiss();
      print('Error signing in with Google: $error');
    }
  }

  Future<Map<String,String>> storeRequiredData() async {
    String email = await utils.getCurrentUserEmail() ?? '';
    String displayName = await utils.getCurrentUserDisplayName() ?? '';
    String name =  utils.removeTextAfterFirstNumber(displayName);
    String imageUrl = await getCurrentUserProfileImage() ?? '';
    String regNo = utils.removeEmailDomain(email);

    Map<String, String> data = {'Email': email, 'Name': name, 'ProfileImageURL': imageUrl,'Registration Number':regNo};
    print('Login Details: $data');

    return data;
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

  @override
  void dispose() {
    super.dispose();
  }

}

