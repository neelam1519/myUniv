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

  /// Send message and update room metadata with the last message and time
  void _handleSendPressed(types.PartialText message) async {
    // Send the message
    FirebaseChatCore.instance.sendMessage(message, widget.room.id);

    print("Message: ${message.toJson()}");
    print("Users:${widget.room.users}");

    // Create the new message object to update room's last messages
    final newMessage = types.TextMessage(
      author: types.User(id: FirebaseChatCore.instance.firebaseUser!.uid),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().toString(),
      text: message.text,
    );

    // Update the room with the new last message
    final updatedRoom = types.Room(
      id: widget.room.id,
      lastMessages: [newMessage],
      type: widget.room.type,
      users: widget.room.users,
      updatedAt: DateTime.now().millisecondsSinceEpoch, // Add current timestamp
    );

    // Update room metadata in Firebase
    FirebaseChatCore.instance.updateRoom(updatedRoom);

    print("Updated Room: ${updatedRoom.toJson()}");
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
}
