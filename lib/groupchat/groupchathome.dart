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

  /// Checks if the user is already registered. If not, registers the user.
  Future<void> ensureUserRegistered() async {
    String? uid = await Utils().getCurrentUserUID();
    if (uid == null) {
      throw Exception("User not logged in");
    }

    // Check if the user already exists in Firestore
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      // If user does not exist, register the user
      String? name = await Utils().getCurrentUserDisplayName();
      if (name == null || name.isEmpty) {
        throw Exception("User display name not found");
      }

      String renamed = Utils().removeTextAfterFirstNumber(name);
      DocumentReference documentReference = FirebaseFirestore.instance.doc('UserDetails/$uid');
      String? url = await SharedPreferences().getDataFromReference(documentReference, 'ProfileImageURL');

      await FirebaseChatCore.instance.createUserInFirestore(
        types.User(
          firstName: renamed,
          id: uid,
          imageUrl: url ?? '',
          lastName: '',
        ),
      );

      print("User registered: $uid");
    } else {
      print("User already registered: $uid");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Group Chats',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateRoomPage()),
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
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          final rooms = snapshot.data ?? [];
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'No groups yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreateRoomPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Create a Group'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final lastMessage = room.lastMessages?.isNotEmpty ?? false
                  ? room.lastMessages!.last
                  : null;

              // Extract last message text and time
              final lastMessageText = lastMessage is types.TextMessage
                  ? lastMessage.text
                  : 'No messages yet';
              final formattedTime = room.updatedAt != null
                  ? Utils.formatTimestamp(room.updatedAt!)
                  : '';
              final unreadCount = room.metadata?['unreadCount'] ?? 0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(room: room),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      radius: 25,
                      child: room.imageUrl != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          room.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Text(
                        room.name != null && room.name!.isNotEmpty
                            ? room.name![0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      room.name ?? 'Unknown Room',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      lastMessageText,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formattedTime,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}