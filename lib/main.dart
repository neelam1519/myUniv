import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'firebase_options.dart';
import 'package:findany_flutter/Home.dart';
import 'package:findany_flutter/Login/login.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:in_app_update/in_app_update.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  NotificationService().showNotification(message);
}

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/transperentlogo'),
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FindAny',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthCheck(),
      builder: EasyLoading.init(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
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
    print('Notification Data: ${message.data}');
    if (message.data['source'] == 'UniversityChat') {
      Navigator.pushNamed(context, '/UniversityChat');
    }
  }

  void _onMessageReceived(RemoteMessage message) {
    print('Received a message while in the foreground!');
    print('Message data: ${message.data}');
    NotificationService().showNotification(message);
  }

  Future<void> _checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((info) {
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        InAppUpdate.performImmediateUpdate().catchError((e) => print(e.toString()));
      }
    }).catchError((e) => print(e.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          EasyLoading.show(status: 'Loading...');
          return Center(child: CircularProgressIndicator());
        } else {
          EasyLoading.dismiss();
          return snapshot.hasData ? Home() : Login();
        }
      },
    );
  }
}
