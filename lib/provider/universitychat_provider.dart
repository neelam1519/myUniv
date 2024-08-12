import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter/cupertino.dart';

import '../services/sendnotification.dart';
import '../utils/sharedpreferences.dart';
import '../utils/utils.dart';

class UniversityChatProvider with ChangeNotifier {
  final Utils utils = Utils();
  final NotificationService notificationService = NotificationService();
  final SharedPreferences sharedPreferences = SharedPreferences();

  late rtdb.DatabaseReference chatRef;
  late rtdb.DatabaseReference onlineUsersRef;
  final List<ChatMessage> _messages = [];
  ChatUser? _user;
  User? firebaseUser = FirebaseAuth.instance.currentUser;
  String? _lastMessageKey;
  bool _isLoadingMore = false;
  bool _isInitialLoadComplete = false;
  late StreamSubscription<rtdb.DatabaseEvent> messageSubscription;
  late StreamSubscription<rtdb.DatabaseEvent> onlineUsersSubscription;
  int _onlineUsersCount = 0;

  ChatUser? get user => _user;
  List<ChatMessage> get messages => _messages;
  bool get isLoadingMore => _isLoadingMore;
  bool get isInitialLoadComplete => _isInitialLoadComplete;
  int get onlineUsersCount => _onlineUsersCount;

  set isLoadingMore(bool value) {
    _isLoadingMore = value;
    notifyListeners();
  }

  set isInitialLoadComplete(bool value) {
    _isInitialLoadComplete = value;
    notifyListeners();
  }

  set onlineUsersCount(int value) {
    _onlineUsersCount = value;
    notifyListeners();
  }

  Future<void> initializeUser() async {
    if (firebaseUser != null) {
      String email = firebaseUser!.email!;
      String userId = utils.removeEmailDomain(email);
      DocumentReference userRef = FirebaseFirestore.instance.doc('UserDetails/${utils.getCurrentUserUID()}');

      String username = await sharedPreferences.getDataFromReference(userRef, "Username") ?? '';
      String displayName = utils.removeTextAfterFirstNumber(firebaseUser!.displayName ?? 'Anonymous');
      String name = username.isNotEmpty ? username : (displayName.isNotEmpty ? displayName : 'Anonymous');

      _user = ChatUser(id: userId, firstName: name);
      notifyListeners();
    }
  }

  void listenForNewMessages() {
    List<String?> keyList = [];
    messageSubscription = chatRef.orderByKey().limitToLast(20).onChildAdded.listen((event) {
      rtdb.DataSnapshot snapshot = event.snapshot;
      var value = snapshot.value;
      keyList.add(snapshot.key);
      if (value is Map) {
        try {
          Map<String, dynamic> messageData = _convertToMapStringDynamic(value);
          _messages.insert(0, ChatMessage.fromJson(messageData));
          notifyListeners();
        } catch (e) {
          print("Error parsing new message: $e");
        }
      }
      _lastMessageKey = keyList.first;
    });

    chatRef.once().then((event) {
      if (!event.snapshot.exists) {
        _isInitialLoadComplete = true;
        notifyListeners();
      } else {
        _isInitialLoadComplete = true;
        notifyListeners();
      }
    }).catchError((error) {
      print("Error fetching messages: $error");
      _isInitialLoadComplete = true;
      notifyListeners();
    });
  }

  void trackOnlineUsers() {
    onlineUsersSubscription = onlineUsersRef.onValue.listen((event) {
      rtdb.DataSnapshot snapshot = event.snapshot;
      if (snapshot.exists) {
        Map<dynamic, dynamic> onlineUsers = snapshot.value as Map<dynamic, dynamic>;
        _onlineUsersCount = onlineUsers.length;
      } else {
        _onlineUsersCount = 0;
      }
      notifyListeners();
    });
  }

  void setUserOnline() {
    if (firebaseUser != null) {
      String userId = firebaseUser!.uid;
      onlineUsersRef.child(userId).set(true);
      onlineUsersRef.child(userId).onDisconnect().remove();
    }
  }

  void setUserOffline() {
    if (firebaseUser != null) {
      String userId = firebaseUser!.uid;
      onlineUsersRef.child(userId).remove();
    }
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || _lastMessageKey == null) return;

    _isLoadingMore = true;
    notifyListeners();

    rtdb.Query query = chatRef.orderByKey().endAt(_lastMessageKey).limitToLast(21);
    try {
      rtdb.DatabaseEvent event = await query.once();
      rtdb.DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        List<ChatMessage> moreMessages = [];
        String? newLastMessageKey;
        for (var childSnapshot in snapshot.children) {
          var value = childSnapshot.value;
          if (value is Map) {
            try {
              Map<String, dynamic> messageData = _convertToMapStringDynamic(value);
              ChatMessage chatMessage = ChatMessage.fromJson(messageData);
              if (childSnapshot.key != _lastMessageKey) {
                moreMessages.add(chatMessage);
              }
              newLastMessageKey = newLastMessageKey ?? childSnapshot.key;
            } catch (e) {
              print("Error parsing message: $e");
            }
          }
        }

        _messages.addAll(moreMessages.reversed.toList());
        _lastMessageKey = newLastMessageKey;
      }

      _isLoadingMore = false;
      notifyListeners();
    } catch (error) {
      print("Error loading more messages: $error");
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> handleSend(ChatMessage message) async {
    final newMessageRef = chatRef.push();
    newMessageRef.set(message.toJson());
    List<String> tokens = await utils.getAllTokens();
    await notificationService.sendNotification(tokens, "Group Chat", message.text, {"source": 'UniversityChat'});
  }

  Map<String, dynamic> _convertToMapStringDynamic(Map<dynamic, dynamic> original) {
    return original.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _convertToMapStringDynamic(value));
      } else {
        return MapEntry(key.toString(), value);
      }
    });
  }
}
