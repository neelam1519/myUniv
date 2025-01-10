import 'dart:async';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class HomeProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FireStoreService fireStoreService = FireStoreService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SharedPreferences sharedPreferences = SharedPreferences();
  LoadingDialog loadingDialog =LoadingDialog();
  final Utils utils = Utils();

  String? email;
  String? name;
  String? imageUrl;
  String? _announcementText;

  Future<void> loadData(BuildContext context) async {
    try {
      final String? currentUserUID = await utils.getCurrentUserUID();

      if (currentUserUID == null) {
        print('No user logged in.');
        return;
      }

      print('Fetching user details from Firestore...');
      DocumentReference userDoc = _firestore.collection('users').doc(currentUserUID);
      DocumentSnapshot userSnapshot = await userDoc.get();

      if (userSnapshot.exists) {
        print('User is an old user. Fetching details...');
        final data = userSnapshot.data() as Map<String, dynamic>?;

        email = data?['Email'] as String? ?? "Unknown";
        name = data?['firstName'] as String? ?? "User";
        imageUrl = data?['imageUrl'] as String? ?? "";


      } else {
        loadingDialog.showDefaultLoading("Hello, New User! Hold tight—We're updating your account");
        print('User is a new user. Setting isNewUser to true.');
        await storeRequiredData(context);
      }

    } catch (error) {
      print('Error loading data: $error');
      utils.showToastMessage('Error occurred while loading user data.');
    }
  }

  Future<void> storeRequiredData(BuildContext context) async {
    try {
      email = await utils.getCurrentUserEmail() ?? " ";
      String firstName = await utils.getCurrentUserDisplayName() ?? " ";
      imageUrl = await utils.getCurrentUserProfileImage() ?? " ";

       name = utils.removeTextAfterFirstNumber(firstName);
      final String regNo = utils.removeEmailDomain(email!);

      User? user = _auth.currentUser;
      String? uid = await utils.getCurrentUserUID();

      if(user !=null) {
        await FirebaseChatCore.instance.createUserInFirestore(
          types.User(
            firstName: name,
            id: uid!,
            imageUrl: imageUrl,
            role: types.Role.user,
            metadata: {},
          ),
        );
      }

      String? token = await utils.getToken();

      final Map<String, String> data = {
        'Email': email!,
        'Registration Number': regNo,
        'fcmToken' : token!,
      };

      final Map<String, String> sharedPreference = {
        'Email': email!,
        'Registration Number': regNo,
        'fcmToken' : token,
        "firstName": name!,
        "imageUrl": imageUrl!,
      };

      print('User Details: $data');

      DocumentReference userToken = FirebaseFirestore.instance.doc('users/$uid');
      fireStoreService.uploadMapDataToFirestore(data, userToken);

      sharedPreferences.storeMapValuesInSecureStorage(sharedPreference);

      loadingDialog.dismiss();
    } catch (error) {
      print('Error storing data: $error');
      utils.showToastMessage('Error occurred while storing data: $error');
      loadingDialog.dismiss();
      utils.signOut(context);
    }
  }

  Future<void> requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.getNotificationSettings();

      // If the permission is already denied, don't ask for it again
      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        // Only request permission if not denied or not determined
        settings = await _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        if (kDebugMode) {
          print('User granted permission: ${settings.authorizationStatus}');
        }
      } else {
        // If permission is already granted or restricted, no need to ask
        if (kDebugMode) {
          print('Notification permission already granted or restricted');
        }
      }
    } catch (error) {
      print('Error requesting notification permissions: $error');
    }
  }


  String? get announcementText => _announcementText;

  String? get getEmail => email;

  String? get getName => name;

  String? get getImageUrl => imageUrl;

}
