import 'dart:async';  // Import this for StreamSubscription
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UniversityChat extends StatefulWidget {
  @override
  _UniversityChatState createState() => _UniversityChatState();
}

class _UniversityChatState extends State<UniversityChat> {
  Utils utils = Utils();
  NotificationService notificationService = new NotificationService();
  LoadingDialog loadingDialog = new LoadingDialog();

  late DatabaseReference _chatRef;
  List<ChatMessage> _messages = [];
  ChatUser? _user;
  User? firebaseUser = FirebaseAuth.instance.currentUser;
  String? _lastMessageKey; // To keep track of pagination
  bool _isLoadingMore = false;
  late StreamSubscription<DatabaseEvent> _messageSubscription;

  @override
  void initState() {
    super.initState();
    _chatRef = FirebaseDatabase.instance.ref().child("chats");
    initializeUser();
    listenForNewMessages();
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }

  void initializeUser() {
    loadingDialog.showDefaultLoading('Loading Messages...');
    if (firebaseUser != null) {
      String email = firebaseUser!.email!;
      String userId = utils.removeEmailDomain(email);
      String name = utils.removeTextAfterFirstNumber(firebaseUser!.displayName ?? 'User');
      if (mounted) {
        setState(() {
          _user = ChatUser(
            id: userId,
            firstName: name,
          );
        });
      }
    }
  }

  void listenForNewMessages() {
    print('Listening For New Messages...');
    List<String?> keyList = [];
    _messageSubscription = _chatRef.orderByKey().limitToLast(20).onChildAdded.listen((event) {
      if (!mounted) return; // Prevent calling setState if the widget is not mounted
      DataSnapshot snapshot = event.snapshot;
      var value = snapshot.value;
      keyList.add(snapshot.key);
      if (value is Map) {
        try {
          Map<String, dynamic> messageData = _convertToMapStringDynamic(value);

          if (mounted) {
            setState(() {
              _messages.insert(0, ChatMessage.fromJson(messageData));
            });
          }
        } catch (e) {
          print("Error parsing new message: $e");
        }
      }
      _lastMessageKey = keyList.first;
      loadingDialog.dismiss();
      print('Last Message: $_lastMessageKey');
    });
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || _lastMessageKey == null) return;

    if (mounted) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    print('LastMessageKey: $_lastMessageKey');

    Query query = _chatRef.orderByKey().endAt(_lastMessageKey).limitToLast(21); // Load 21 to account for the last message key overlap
    DatabaseEvent event = await query.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.exists) {
      List<ChatMessage> moreMessages = [];
      String? newLastMessageKey;
      snapshot.children.forEach((childSnapshot) {
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
      });

      if (mounted) {
        setState(() {
          _messages.addAll(moreMessages.reversed.toList());
          _lastMessageKey = newLastMessageKey;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _handleSend(ChatMessage message) async{
    final newMessageRef = _chatRef.push();
    newMessageRef.set(message.toJson());
    List<String> tokens = await utils.getAllTokens();
    await notificationService.sendNotification(tokens, "Group Chat", message.text, {"source":'UniversityChat'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('University Chat'),
      ),
      body: _user == null
          ? Center(child: CircularProgressIndicator())
          : DashChat(
        currentUser: _user!,
        onSend: _handleSend,
        messages: _messages,
        messageListOptions: MessageListOptions(
          onLoadEarlier: loadMoreMessages,
        ),
      ),
    );
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
