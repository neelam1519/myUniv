import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import '../groupchat/chatting.dart';

class AuthProviderStart with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  AuthProviderStart() {
    _setupInteractedMessage();
    FirebaseMessaging.onMessage.listen(_onMessageReceived);
    _checkForUpdate();
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> _setupInteractedMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
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
    print('Received a message while in the foreground! ${Chatting.isChatOpen}');
    print('Message data: ${message.data}');
    print(Chatting.groupName.replaceAll(" ", ""));
    print(message.data["title"]);
    if (Chatting.isChatOpen && Chatting.groupName.replaceAll(" ", "") == message.data["title"]) {
      print('Message belongs to UniversityChat and chat is open.');
    } else {
      _notificationService.showNotification(message);
    }
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
