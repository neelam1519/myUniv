import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/groupchat/CreateRoom.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'chatscreen.dart';

class GroupChatHome extends StatelessWidget {
  const GroupChatHome({super.key});


  Future<void> registerUser() async{
    String? uid = await Utils().getCurrentUserUID();
    print("UID: $uid");
    String? name = await Utils().getCurrentUserDisplayName();
    String renamed = Utils().removeTextAfterFirstNumber(name!);
    DocumentReference documentReference = FirebaseFirestore.instance.doc('UserDetails/$uid');
    String url = await SharedPreferences().getDataFromReference(documentReference, 'ProfileImageURL');

    await FirebaseChatCore.instance.createUserInFirestore(
      types.User(
        firstName: renamed,
        id: uid!,
        imageUrl: url ?? '',
        lastName: 'Doe',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Group Chats',
          style: GoogleFonts.dosis(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Add a "+" icon button to create a new room
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: () async {
              // Navigate to the CreateRoomPage when the + button is tapped

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateRoomPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<types.Room>>(
        stream: FirebaseChatCore.instance.rooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final rooms = snapshot.data ?? [];
          print("Rooms: $rooms");

          if (rooms.isEmpty) {
            return const Center(
              child: Text(
                'No groups available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final lastMessage = room.metadata?['lastMessage'] ?? 'No messages yet';
              final formattedTime = room.metadata?['lastMessageTime'] ?? 'no last time';

              return ListTile(
                title: Text(room.name!),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMessage,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(room: room),
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
