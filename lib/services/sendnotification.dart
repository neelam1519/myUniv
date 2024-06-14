import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../main.dart';

class NotificationService {
  final String serverKey = 'AAAAFHHAFOw:APA91bGXjNz0n9hlTXJ7DvqZfvWdPUA4niCrjyk5aFtVD6RbY5IUKIF_e1NlTQ3Z3tj9N0Q4mFENnU-K4BRFwmh6_Ht7iz6Qic6WjOMOehLDYPqXDOURoguGB19-WcQSBvATpK0YQScV';
  final String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

  Future<void> sendNotification(List<dynamic> tokens, String title, String message, Map<String, dynamic> additionalData) async {

    final Map<String, dynamic> payload = {
      'data': {
        'title': title,
        'body': message,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        ...additionalData,
      },
      'registration_ids': tokens,
    };

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final http.Response response = await http.post(
      Uri.parse(fcmEndpoint),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.statusCode}');
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    print('showNotification Data: ${message.data}');

    final String? title = message.data['title'];
    final String? body =  message.data['body'];

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
      payload: message.data['source'] ?? 'notification_payload', // Payload
    );
  }
}