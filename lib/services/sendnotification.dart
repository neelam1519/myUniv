import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendNotification(List<String> tokens) async {
  final String serverKey = 'YOUR_SERVER_KEY';
  final String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

  final Map<String, dynamic> payload = {
    'notification': {
      'title': 'New Message',
      'body': 'You have a new message!',
      'click_action': 'FLUTTER_NOTIFICATION_CLICK', // Optional
    },
    'registration_ids': tokens, // List of FCM tokens
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