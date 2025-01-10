import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:findany_flutter/services/sendnotification.dart';

class AuthProviderStart with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  AuthProviderStart() {
    print('Running auth start');
    _setupInteractedMessage(); // Handle notification if the app was launched by one
    FirebaseMessaging.onMessage.listen(_onMessageReceived); // Foreground messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage); // Background notification click
    _checkForUpdate();
  }


  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> _setupInteractedMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }


  void _handleMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification Clicked: ${message.data}');
    }

    final route = message.data['route']; // Example: extract `route` from data
    if (route != null) {
      print('Navigating to route: $route');
      // Navigate to the specified route (adjust context usage as needed):
      // You may need a BuildContext if navigation depends on Flutter's Navigator
      // For example:
      // Navigator.pushNamed(context, route);
    }
  }

  void _onMessageReceived(RemoteMessage message) {
    print('Foreground Notification Received');
    _notificationService.showNotification(message);
  }


  Future<void> _checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((info) {
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        InAppUpdate.performImmediateUpdate();
      }
    });
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
