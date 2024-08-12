import 'package:flutter/foundation.dart';
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
    if (kDebugMode) {
      print('Handle Google Sign-In');
    }
    try {
      loadingDialog.showDefaultLoading('Signing In...');
      GoogleSignInAccount? googleSignInAccount;

      if (kIsWeb) {
        await webGoogleSignIn(context);
      } else {
        googleSignInAccount = await mobileGoogleSignIn();

        if (googleSignInAccount != null) {
          if (context.mounted) {
            await firebaseSignIn(googleSignInAccount, context);
          }
        } else {
          if (kDebugMode) {
            print('Google Sign-In canceled.');
          }
          loadingDialog.dismiss();
        }
      }
    } catch (error) {
      loadingDialog.dismiss();
      utils.showToastMessage(
        'Error occurred while logging in',
      );
      if (kDebugMode) {
        print('Error signing in with Google: $error');
      }
      await signOut();
    }
  }

  Future<void> webGoogleSignIn(BuildContext context) async {
    if (kDebugMode) {
      print('Entered web sign-in');
    }
    try {
      final GoogleAuthProvider provider = GoogleAuthProvider();
      provider.addScope('https://www.googleapis.com/auth/contacts.readonly');
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
      final OAuthCredential? credential = userCredential.credential as OAuthCredential?;
      final String? accessToken = credential?.accessToken;
      final String? idToken = credential?.idToken;

      if (kDebugMode) {
        print('Access Token: $accessToken');
      }
      if (kDebugMode) {
        print('ID Token: $idToken');
      }
      final User? user = userCredential.user;

      if (user != null) {
        final String? email = user.email;
        if (kDebugMode) {
          print('Email: $email');
        }
        // if (email != null && email.endsWith('@klu.ac.in')) {
        //   if (kDebugMode) {
        //     print('User logged in with the University Email');
        //   }
        //   if (context.mounted) {
        //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
        //     await storeRequiredData(context);
        //   }
        // }

        if (email != null && email.endsWith('@gmail.com')) {
          if (kDebugMode) {
            print('User logged in with the University Email');
          }
          if (context.mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
            await storeRequiredData(context);
          }
        }
        else {
          await signOut();
          loadingDialog.dismiss();
          loadingDialog.showError('Please sign in with a valid KARE email.');
        }
      } else {
        if (kDebugMode) {
          print('User is null after signing in.');
        }
        await signOut();
        loadingDialog.dismiss();
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error during web Google Sign-In: $error');
      }
      utils.showToastMessage(
        'Error occurred while logging in',
      );
      await signOut();
    }
  }

  Future<GoogleSignInAccount?> mobileGoogleSignIn() async {
    GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
    googleSignInAccount ??= await googleSignIn.signIn();
    return googleSignInAccount;
  }

  Future<void> firebaseSignIn(GoogleSignInAccount googleSignInAccount, BuildContext context) async {
    final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

    if (kDebugMode) {
      print('Access Token: ${googleSignInAuthentication.accessToken}');
    }
    if (kDebugMode) {
      print('ID Token: ${googleSignInAuthentication.idToken}');
    }

    if (googleSignInAuthentication.accessToken == null || googleSignInAuthentication.idToken == null) {
      throw Exception('Google Sign-In authentication tokens are null');
    }

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = authResult.user;

    if (user != null && context.mounted) {
      final String? email = user.email;
      if (kDebugMode) {
        print('Email: $email');
      }
      if (email != null && email.endsWith('@klu.ac.in')) {
        if (kDebugMode) {
          print('User logged in with the University Email');
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
        await storeRequiredData(context);
      } else {
        await signOut();
        loadingDialog.dismiss();
        loadingDialog.showError('Please sign in with a valid KARE email.');
      }
    } else {
      if (kDebugMode) {
        print('User is null after signing in.');
      }
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

      if (kDebugMode) {
        print('Login Token : $token');
      }

      String name = utils.removeTextAfterFirstNumber(displayName);
      String regNo = utils.removeEmailDomain(email);

      Map<String, String> data = {
        'Email': email,
        'Name': name,
        'ProfileImageURL': imageUrl,
        'Registration Number': regNo,
      };
      if (kDebugMode) {
        print('Login Details: $data');
      }

      String? currentUserUID = await utils.getCurrentUserUID();

      DocumentReference documentReference = FirebaseFirestore.instance.doc('/UserDetails/$currentUserUID');
      fireStoreService.uploadMapDataToFirestore(data, documentReference);
      sharedPreferences.storeMapValuesInSecureStorage(data);

      DocumentReference tokenRef = FirebaseFirestore.instance.doc('Tokens/Tokens');
      await fireStoreService.uploadMapDataToFirestore({regNo: token}, tokenRef);
      loadingDialog.dismiss();
    } catch (error) {
      if (kDebugMode) {
        print('Error storing data: $error');
      }
      utils.showToastMessage('Error occurred while login $error');
      if (kDebugMode) {
        print('Login Error2: $error');
      }
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

