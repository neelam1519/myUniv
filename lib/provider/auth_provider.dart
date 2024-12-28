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
    _setupInteractedMessage();
    FirebaseMessaging.onMessage.listen(_onMessageReceived);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    _checkForUpdate();
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> _setupInteractedMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);
  }

  void _handleMessage(RemoteMessage message) {
    print('Clicked the notification');
    if (kDebugMode) {
      print('Entered handle message');
    }
    if (kDebugMode) {
      print('Notification Data: ${message.data}');
    }
    if (message.data['source'] != null) {
      print('Source is not null: ${message.data['source']}');
    }
  }

  void _onMessageReceived(RemoteMessage message) {
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
