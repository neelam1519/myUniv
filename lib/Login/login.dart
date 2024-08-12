// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:findany_flutter/Firebase/firestore.dart';
// import 'package:findany_flutter/Home.dart';
// import 'package:findany_flutter/utils/LoadingDialog.dart';
// import 'package:findany_flutter/utils/sharedpreferences.dart';
// import 'package:findany_flutter/utils/utils.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_signin_button/flutter_signin_button.dart';
//
// class Login extends StatefulWidget {
//   const Login({super.key});
//
//   @override
//   State<Login> createState() => _LoginState();
// }
//
// class _LoginState extends State<Login> {
//   Utils utils = Utils();
//   LoadingDialog loadingDialog = LoadingDialog();
//   SharedPreferences sharedPreferences = SharedPreferences();
//   FireStoreService fireStoreService = FireStoreService();
//
//   final GoogleSignIn googleSignIn = GoogleSignIn(
//     scopes: [
//       'email',
//       'profile',
//       'https://www.googleapis.com/auth/userinfo.email',
//       'https://www.googleapis.com/auth/userinfo.profile',
//       'openid'
//     ],
//   );
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Login', style: TextStyle(fontSize: 20, letterSpacing: 1.5, fontWeight: FontWeight.w700),),
//         backgroundColor: Colors.green[400],
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               Image.asset(
//                 'assets/images/logo.png',
//                 height: 120.0,
//               ),
//               const SizedBox(height: 40.0),
//               const Text(
//                 'Welcome to FindAny',
//                 style: TextStyle(
//                   fontSize: 24.0,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 20.0),
//               SignInButton(
//                 Buttons.Google,
//                 text: "Sign in with Google",
//                 onPressed: () async {
//                   bool internet = await utils.checkInternetConnection();
//                   print('Internet Connection: $internet');
//                   if (internet) {
//                     await _handleGoogleSignIn(context);
//                   } else {
//                     utils.showToastMessage('Check your internet connection', context);
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _handleGoogleSignIn(BuildContext context) async {
//     print('Handle Google Sign-In');
//     try {
//       loadingDialog.showDefaultLoading('Signing In...');
//       GoogleSignInAccount? googleSignInAccount;
//
//       if (kIsWeb) {
//         await _webGoogleSignIn(context);
//       } else {
//         googleSignInAccount = await _mobileGoogleSignIn();
//
//         if (googleSignInAccount != null) {
//           await _firebaseSignIn(googleSignInAccount, context);
//         } else {
//           print('Google Sign-In canceled.');
//           loadingDialog.dismiss();
//         }
//       }
//     } catch (error) {
//       loadingDialog.dismiss();
//       utils.showToastMessage('Error occurred while logging in', context);
//       print('Error signing in with Google: $error');
//       await signOut();
//     }
//   }
//
//   Future<void> _webGoogleSignIn(BuildContext context) async {
//     print('Entered web sign-in');
//     try {
//       final GoogleAuthProvider provider = GoogleAuthProvider();
//       provider.addScope('https://www.googleapis.com/auth/contacts.readonly');
//       final UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
//       final OAuthCredential? credential = userCredential.credential as OAuthCredential?;
//       final String? accessToken = credential?.accessToken;
//       final String? idToken = credential?.idToken;
//
//       print('Access Token: $accessToken');
//       print('ID Token: $idToken');
//       final User? user = userCredential.user;
//
//       if (user != null) {
//         final String? email = user.email;
//         print('Email: $email');
//         if (email != null && email.endsWith('@klu.ac.in')) {
//           print('User logged in with the University Email');
//           Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
//           await storeRequiredData();
//         } else {
//           await signOut();
//           loadingDialog.dismiss();
//           loadingDialog.showError('Please sign in with a valid KARE email.');
//         }
//       } else {
//         print('User is null after signing in.');
//         await signOut();
//         loadingDialog.dismiss();
//       }
//     } catch (error) {
//       // Handle Errors here
//       print('Error during web Google Sign-In: $error');
//       utils.showToastMessage('Error occurred while logging in', context);
//       await signOut();
//     }
//   }
//
//   /// Handles Google Sign-In for mobile (Android/iOS)
//   Future<GoogleSignInAccount?> _mobileGoogleSignIn() async {
//     GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
//     googleSignInAccount ??= await googleSignIn.signIn();
//     return googleSignInAccount;
//   }
//
//   /// Handles Firebase authentication
//   Future<void> _firebaseSignIn(GoogleSignInAccount googleSignInAccount, BuildContext context) async {
//     final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
//
//     print('Access Token: ${googleSignInAuthentication.accessToken}');
//     print('ID Token: ${googleSignInAuthentication.idToken}');
//
//     if (googleSignInAuthentication.accessToken == null || googleSignInAuthentication.idToken == null) {
//       throw Exception('Google Sign-In authentication tokens are null');
//     }
//
//     final AuthCredential credential = GoogleAuthProvider.credential(
//       accessToken: googleSignInAuthentication.accessToken,
//       idToken: googleSignInAuthentication.idToken,
//     );
//
//     final UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(credential);
//     final User? user = authResult.user;
//
//     if (user != null && context.mounted) {
//       final String? email = user.email;
//       print('Email: $email');
//       if (email != null && email.endsWith('@klu.ac.in')) {
//         print('User logged in with the University Email');
//         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
//         await storeRequiredData();
//       } else {
//         await signOut();
//         loadingDialog.dismiss();
//         loadingDialog.showError('Please sign in with a valid KARE email.');
//       }
//     } else {
//       print('User is null after signing in.');
//       await signOut();
//       loadingDialog.dismiss();
//     }
//   }
//
//   Future<void> storeRequiredData() async {
//     try {
//       String email = await utils.getCurrentUserEmail() ?? " ";
//       String displayName = await utils.getCurrentUserDisplayName() ?? " ";
//       String imageUrl = await utils.getCurrentUserProfileImage() ?? " ";
//       String token = await utils.getToken() ?? " ";
//
//       print('Login Token : $token');
//
//       String name = utils.removeTextAfterFirstNumber(displayName);
//       String regNo = utils.removeEmailDomain(email);
//
//       Map<String, String> data = {
//         'Email': email,
//         'Name': name,
//         'ProfileImageURL': imageUrl,
//         'Registration Number': regNo,
//       };
//       print('Login Details: $data');
//
//       String? currentUserUID = await utils.getCurrentUserUID();
//
//       DocumentReference documentReference = FirebaseFirestore.instance.doc('/UserDetails/$currentUserUID');
//       fireStoreService.uploadMapDataToFirestore(data, documentReference);
//       sharedPreferences.storeMapValuesInSecureStorage(data);
//
//       DocumentReference tokenRef = FirebaseFirestore.instance.doc('Tokens/Tokens');
//       await fireStoreService.uploadMapDataToFirestore({regNo: token}, tokenRef);
//       loadingDialog.dismiss();
//
//     } catch (error) {
//       print('Error storing data: $error');
//       utils.showToastMessage('Error occurred while login $error', context);
//       print('Login Error2: $error');
//       await signOut();
//     }
//   }
//
//   Future<void> signOut() async {
//     await FirebaseAuth.instance.signOut();
//     await googleSignIn.disconnect();
//     await googleSignIn.signOut();
//   }
// }



import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:provider/provider.dart';

import '../provider/login_provider.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                'Welcome to FindAny',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20.0),
              Consumer<LoginProvider>(
                builder: (context, loginProvider, child) {
                  return SignInButton(
                    Buttons.Google,
                    text: "Sign in with Google",
                    onPressed: () async {
                      bool internet = await loginProvider.utils.checkInternetConnection();
                      if (kDebugMode) {
                        print('Internet Connection: $internet');
                      }
                      if (internet) {
                        if (context.mounted) {
                          await loginProvider.handleGoogleSignIn(context);
                        }
                      } else {
                        loginProvider.utils.showToastMessage('Check your internet connection');
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}