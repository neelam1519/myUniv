import 'dart:io';
import 'package:findany_flutter/Home.dart';
import 'package:findany_flutter/Login/login.dart';
import 'package:findany_flutter/groupchat/universitychat.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:path_provider/path_provider.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message: ${message.messageId}");

  if (message.messageId != null) {
    print('Background message data: ${message.data}');
  } else {
    print('MessageId is null');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> showNotification(RemoteMessage message) async {
  if (message.data['from'] == 'firebase') {
    return;
  }
  final String? title = message.notification?.title;
  final String? body = message.notification?.body;

  final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'Neelam',
    'FindAny',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker', // Ticker
    icon: '@mipmap/transperentlogo',
  );

  final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    title, // Notification title
    body, // Notification body
    platformChannelSpecifics, // Notification details
    payload: 'notification_payload', // Payload
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Utils utils = Utils();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(AppLifecycleListener());
    setupInteractedMessage();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.messageId != null) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
        showNotification(message);

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
        }
      }
    });

    checkForUpdate();
  }

  Future<void> setupInteractedMessage() async {
    print('On Notification Clicked');
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(context, initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(context, message);
    });
  }

  void _handleMessage(BuildContext context, RemoteMessage message) {
    print('On Notification clicked: ${message.data}');
    if (message.data['source'] == 'UniversityChat') {
      print('Notification navigation to UniversityChat');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UniversityChat()),
      );
    } else {
      print('Notification navigation to Home');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    }
  }

  Future<void> checkForUpdate() async {
    if (await utils.checkInternetConnection()) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          final appUpdateResult = await InAppUpdate.performImmediateUpdate();
          if (appUpdateResult == AppUpdateResult.success) {
            print('Updated successfully');
          } else {
            print('Unable to update');
          }
        } else {
          print('No update available');
        }
      } catch (e) {
        print('Error checking for update: $e');
      }
    } else {
      print('No internet connection, no update checked');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      title: 'Flutter Demo',
      home: AuthWrapper(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(AppLifecycleListener());
    super.dispose();
    print('Main Disposed');
  }
}

class AuthWrapper extends StatelessWidget {
  Utils utils = Utils();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          if (snapshot.data != null) {
            return Home();
          } else {
            return Login();
          }
        }
      },
    );
  }
}

class AppLifecycleListener with WidgetsBindingObserver {
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    final isDetached = state == AppLifecycleState.detached;
    print('State: $state');
    if (isDetached) {
      Utils utils = Utils();
      //utils.deleteFolder('/data/data/com.neelam.FindAny/cache');
      //clearCache();
      print('Detached');
    }
  }

  Future<void> clearCache() async {
    print('Clearing cache');
    final cacheDir = await getApplicationSupportDirectory();
    final cachePath = '${cacheDir.path}/cache';
    final dir = Directory(cachePath);
    await dir.delete(recursive: true);
  }
}
