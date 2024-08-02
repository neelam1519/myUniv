import 'package:findany_flutter/LecturersHome.dart';
import 'package:findany_flutter/groupchat/chatting.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:findany_flutter/watchmenHome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:findany_flutter/Home.dart';
import 'package:findany_flutter/Login/login.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:in_app_update/in_app_update.dart';

import 'leaveforms/leaveformprovider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  NotificationService().showNotification(message);
}

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kIsWeb) {
    final GoogleSignIn _googleSignIn = GoogleSignIn(
      clientId: '87807759596-ijh25ipt7ig7bq78jl2lr70qjmhdu1m5.apps.googleusercontent.com',
    );
    try {
      await _googleSignIn.signInSilently();
    } catch (error) {
      print('Error during Google Sign-In initialization: $error');
    }
  }

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/transperentlogo'),
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LeaveFormProvider())
      ],
      child:MaterialApp(
        title: 'FindAny',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: AuthCheck(),
        builder: EasyLoading.init(),
      ),

    );
  }
}

class AuthCheck extends StatefulWidget {
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {

  Utils utils =Utils();
  @override
  void initState() {
    super.initState();
    _setupInteractedMessage();
    FirebaseMessaging.onMessage.listen(_onMessageReceived);
    _checkForUpdate();
  }

  Future<void> _setupInteractedMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    print('Entered handle message');
    print('Notification Data: ${message.data}');
    if (message.data['source'] != null) {
      print('Source is not null: ${message.data['source']}');
      Navigator.pushNamed(context, message.data['source']);
    }
  }

  void _onMessageReceived(RemoteMessage message) {
    print('Received a message while in the foreground!');
    print('Message data: ${message.data}');

    if (Chatting.isChatOpen && Chatting.groupName == message.data["title"]) {
      print('Message belongs to UniversityChat and chat is open.');
    } else {
      NotificationService().showNotification(message);
    }
  }

  Future<void> _checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((info) {
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        InAppUpdate.performImmediateUpdate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Utils utils = Utils();

    Future<void> checkUserEmail() async {
      String? email = await utils.getCurrentUserEmail();
      if (email != null && utils.isEmailPrefixNumeric(email)) {
        print('User logged in with the Student Email');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
      } else {
        SharedPreferences sharedPreferences = SharedPreferences();
        String value = await sharedPreferences.getSecurePrefsValue("LoginType");

        print('LoginType: $value');

        if (value == "WATCHMEN") {
          print('User logged in with the Lecturer Email');
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => Watchmenhome()));
        } else {
          print('User logged in with the Lecturer Email');
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => Lecturershome()));
        }
      }
    }
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      checkUserEmail();
      return Container();
    } else {
      return Login();
    }
  }

}