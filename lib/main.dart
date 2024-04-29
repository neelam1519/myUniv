import 'dart:io';

import 'package:findany_flutter/Home.dart';
import 'package:findany_flutter/Login/login.dart';
import 'package:findany_flutter/groupchat/universitychat.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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

  if(message.messageId != null ){
    print('testing ${message.data}');
  }else{
    print('MessageId is null');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set auto initialization for Firebase Messaging
  await FirebaseMessaging.instance.setAutoInitEnabled(true);

  // Set background message handler for Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Listen for messages received while the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.messageId != null) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.from}');
      showNotification(message);

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    }
  });
  // Run the app
  runApp(MyApp());
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();


Future<void> showNotification(RemoteMessage message) async {

  if (message.data['from'] == 'firebase') {
    return;
  }
  // Notification details
  print('Showing notification');
  final String? title = message.notification?.title;
  final String? body = message.notification?.body;

  final AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    icon: '@mipmap/ic_launcher',
  );

  final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  // Show the notification
  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    title,
    body,
    platformChannelSpecifics,
    payload: 'notification_payload',
  );
}


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>{
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(AppLifecycleListener());
    setupInteractedMessage();
  }

  Future<void> setupInteractedMessage() async {
    print('On Notification Clicked');
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(context, initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(context, message);
    });
  }

  void _handleMessage(BuildContext context, RemoteMessage message) {
    print('On Notification clicked');
    if (message.data['source'] == 'UniversityChat') {
      print('Notification navigation to UniversityChat');
      Navigator.push(context, MaterialPageRoute(builder: (context) => UniversityChat()),);
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
    // TODO: implement dispose
    super.dispose();
    print('Main Disposed');
  }
}

class AuthWrapper extends StatelessWidget {
  Utils utils = new Utils();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance
          .authStateChanges()
          .first,
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

  Future<void> checkForUpdate() async {
    if (await utils.checkInternetConnection()) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          final appUpdateResult = await InAppUpdate.performImmediateUpdate();
          if (appUpdateResult == AppUpdateResult.success) {
            print('Updated successfully');
          } else {
            print('Unable to updated');
          }
        } else {
          print('No update available');
        }
      } catch (e) {
        print('Error checking for update: $e');
      }
    } else {
      print('No internet connection no update checked');
    }
  }
}

class AppLifecycleListener with WidgetsBindingObserver {
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    final isDetached = state == AppLifecycleState.detached;
    print('State: $state');
    if (isDetached) {
      Utils utils = new Utils();
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
