import 'dart:convert';
import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final String serverKey = 'AAAAFHHAFOw:APA91bGXjNz0n9hlTXJ7DvqZfvWdPUA4niCrjyk5aFtVD6RbY5IUKIF_e1NlTQ3Z3tj9N0Q4mFENnU-K4BRFwmh6_Ht7iz6Qic6WjOMOehLDYPqXDOURoguGB19-WcQSBvATpK0YQScV';
  final String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';


  void initialize(){
    AwesomeNotifications().initialize(
      'assets/images/logo.png', // App icon
      [
        NotificationChannel(
          channelKey: 'Neelam',
          channelName: 'myUniv',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: true,
        ),
      ],
    );
  }

  Future<void> showNotification(RemoteMessage message) async {
    print('showNotification Data: ${message.toMap()}');

    final String? title = message.notification?.title;
    final String? body = message.notification?.body;

    // Parse additional data if needed
    final Map<String, dynamic> data = message.data;

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10, // Unique notification ID
        channelKey: 'basic_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default, // Customizable layout
        payload: data.map((key, value) => MapEntry(key, value.toString())), // Add custom payload
      ),
    );
  }

  Future<void> sendNotification(List<dynamic> tokens, String title, String message, Map<String, dynamic> additionalData) async {
    const int maxTokensPerBatch = 1000;

    for (int i = 0; i < tokens.length; i += maxTokensPerBatch) {
      final List<dynamic> tokenBatch = tokens.sublist(
        i,
        i + maxTokensPerBatch > tokens.length ? tokens.length : i + maxTokensPerBatch,
      );

      final Map<String, dynamic> payload = {
        'data': {
          'title': title,
          'body': message,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          ...additionalData,
        },
        'registration_ids': tokenBatch,
      };

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      };

      print('Sending notification with payload: ${jsonEncode(payload)}');
      print('Using server key: $serverKey');

      try {
        final http.Response response = await http.post(
          Uri.parse(fcmEndpoint),
          headers: headers,
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          print('Notification sent successfully to batch ${i ~/ maxTokensPerBatch + 1}');
        } else {
          print('Failed to send notification to batch ${i ~/ maxTokensPerBatch + 1}: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
      } catch (e) {
        print('Exception occurred while sending notification to batch ${i ~/ maxTokensPerBatch + 1}: $e');
      }
    }
  }



}
