import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SharedPreferences _sharedPreferences = SharedPreferences();
  final Utils utils = Utils();
  final LoadingDialog _loadingDialog = LoadingDialog();

  String? email;
  String? name;
  String? imageUrl;
  String? _announcementText;
  StreamSubscription<DatabaseEvent>? _announcementSubscription;

  Future<void> loadData() async {
    _loadingDialog.showDefaultLoading("Getting Details...");
    DocumentReference documentReference = _firestore.doc('/UserDetails/${utils.getCurrentUserUID()}');
    email = await _sharedPreferences.getDataFromReference(documentReference, 'Email') ?? '';
    name = await _sharedPreferences.getDataFromReference(documentReference, "Name") ?? '';
    imageUrl = await _sharedPreferences.getDataFromReference(documentReference, 'ProfileImageURL') ?? '';
    await utils.updateToken();
    _loadingDialog.dismiss();
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
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
  }

  Future<void> fetchAnnouncementText() async {
    final DatabaseReference announcementRef = _database.ref('Home');
    _announcementSubscription = announcementRef.onValue.listen((event) {
      _announcementText = event.snapshot.exists ? (event.snapshot.value as Map)['Announcement'] : null;
    });
  }

  Future<void> signOut() async {
    _loadingDialog.showDefaultLoading('Signing Out...');
    try {
      await _auth.signOut();
      await GoogleSignIn().disconnect();
      utils.deleteFile('/data/data/com.neelam.FindAny/shared_prefs/FlutterSecureStorage.xml');
      utils.deleteFolder('/data/data/com.neelam.FindAny/cache/libCachedImageData');
      utils.deleteFolder('/data/data/com.neelam.FindAny/databases');
      _loadingDialog.dismiss();
    } catch (error) {
      if (kDebugMode) {
        print("Error signing out: $error");
      }
      _loadingDialog.dismiss();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _announcementSubscription?.cancel();
  }

  String? get announcementText => _announcementText;

  String? get getEmail => email;

  String? get getName => name;

  String? get getImageUrl => imageUrl;
}
