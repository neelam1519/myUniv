import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatScreen extends StatefulWidget {
  final types.Room room;

  const ChatScreen({Key? key, required this.room}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  late types.User _user;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final firebaseUser = FirebaseChatCore.instance.firebaseUser;
    if (firebaseUser != null) {
      setState(() {
        _user = types.User(id: firebaseUser.uid);
      });
    }
  }

  Future<void> _loadMessages() async {
    FirebaseChatCore.instance.messages(widget.room).listen((messages) {
      setState(() {
        _messages = messages;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.name ?? 'Group Chat'),
      ),
      body: SafeArea(
        child: Chat(
          messages: _messages,
          onSendPressed: _handleSendPressed,
          user: _user,
        ),
      ),
    );
  }

  void _handleSendPressed(types.PartialText message) {
     FirebaseChatCore.instance.sendMessage(message, widget.room.id);
  }
}
