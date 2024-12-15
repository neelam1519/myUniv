import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatGroupListScreen extends StatelessWidget {
  const ChatGroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Groups'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<List<types.Room>>(
        stream: FirebaseChatCore.instance.rooms(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!;

          if (rooms.isEmpty) {
            return const Center(child: Text('No chat groups available.'));
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: room.imageUrl != null
                      ? NetworkImage(room.imageUrl!)
                      : const AssetImage('assets/images/groupicon.png')
                  as ImageProvider,
                ),
                title: Text(room.name ?? 'Unnamed Group'),
                subtitle: Text(room.metadata?['description'] ?? 'No description'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(room: room),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final types.Room room;

  const ChatScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(room.name ?? 'Chat'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<List<types.Message>>(
        stream: FirebaseChatCore.instance.messages(room),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Chat(
            messages: snapshot.data!,
            onSendPressed: (partialMessage) {
              final user = FirebaseAuth.instance.currentUser!;
              final message = types.TextMessage(
                author: types.User(id: user.uid),
                createdAt: DateTime.now().millisecondsSinceEpoch,
                id: DateTime.now().toString(),
                text: partialMessage.text,
              );
              FirebaseChatCore.instance.sendMessage(message, room.id);
            },
            user: types.User(id: FirebaseAuth.instance.currentUser!.uid),
          );
        },
      ),
    );
  }
}
