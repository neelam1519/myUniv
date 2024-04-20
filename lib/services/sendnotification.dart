import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {

  Future<void> sendNotification(List<dynamic> tokens, String title, String message, Map<String, dynamic> additionalData) async {
    final String serverKey = 'AAAAFHHAFOw:APA91bGXjNz0n9hlTXJ7DvqZfvWdPUA4niCrjyk5aFtVD6RbY5IUKIF_e1NlTQ3Z3tj9N0Q4mFENnU-K4BRFwmh6_Ht7iz6Qic6WjOMOehLDYPqXDOURoguGB19-WcQSBvATpK0YQScV';
    final String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

    final Map<String, dynamic> payload = {
      'notification': {
        'title': title,
        'body': message,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK', // Optional
      },
      'data': additionalData, // Additional data
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
}