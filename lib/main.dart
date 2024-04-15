
import 'package:findany_flutter/Home.dart';
import 'package:findany_flutter/Login/login.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:in_app_update/in_app_update.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  //await showNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    //showNotification(message);

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });

  runApp(MyApp());
  AuthWrapper().checkForUpdate();

}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();

//
// Future<void> showNotification(RemoteMessage message) async {
//   // Notification details
//   print('Showing notification');
//   final String? title = message.notification?.title;
//   final String? body = message.notification?.body;
//
//   final AndroidNotificationDetails androidPlatformChannelSpecifics =
//   AndroidNotificationDetails(
//     'channel_id',
//     'channel_name',
//     importance: Importance.max,
//     priority: Priority.high,
//     ticker: 'ticker',
//     icon: '@mipmap/ic_launcher',
//   );
//
//   final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
//
//   // Show the notification
//   await flutterLocalNotificationsPlugin.show(
//     0, // Notification ID
//     title,
//     body,
//     platformChannelSpecifics,
//     payload: 'notification_payload',
//   );
// }


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      title: 'Flutter Demo',
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  Utils utils = new Utils();

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
