import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:provider/provider.dart';
import 'chatcard.dart';
import 'groupchathome_provider.dart';
import 'CreateRoom.dart';
import 'chatscreen.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';

class GroupChatHome extends StatefulWidget {
  const GroupChatHome({Key? key}) : super(key: key);

  @override
  _GroupChatHomeState createState() => _GroupChatHomeState();
}

class _GroupChatHomeState extends State<GroupChatHome> {
  late GroupChatHomeProvider provider;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<GroupChatHomeProvider>(context, listen: false);
    provider.fetchUnJoinedGroups();
    provider.checkAdminStatus();
  }

  Widget _buildJoinedGroups() {
    return StreamBuilder<List<types.Room>>(
      stream: FirebaseChatCore.instance.rooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "No Groups available",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        final rooms = snapshot.data!;

        return Column(
          children: rooms.map((room) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(room.id)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, messageSnapshot) {
                String lastMessage = "No messages yet";
                DateTime lastMessageTime = DateTime.now(); // Default value
                String profileImageUrl =
                    room.imageUrl ?? "assets/images/groupchat.png";

                if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                  final lastMessageData = messageSnapshot.data!.docs.first.data()
                  as Map<String, dynamic>;

                  // Safely check if 'text' exists
                  if (lastMessageData.containsKey('text')) {
                    lastMessage = lastMessageData['text'] as String;
                  } else if (lastMessageData.containsKey('name')) {
                    // Fallback for file or image messages with a 'name' field
                    lastMessage = "File: ${lastMessageData['name']}";
                  } else {
                    lastMessage = "Unsupported message type";
                  }

                  // Safely handle 'createdAt' field
                  if (lastMessageData.containsKey('createdAt')) {
                    final timestamp = lastMessageData['createdAt'] as Timestamp?;
                    if (timestamp != null) {
                      lastMessageTime = timestamp.toDate();
                    }
                  }
                }

                return GestureDetector(
                  onTap: () {
                    print("Clicked on Room ID: ${room.id}");
                    // Navigate to the room's chat screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(room: room),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ChatCard(
                      chatName: room.name ?? "Untitled Room",
                      lastMessage: lastMessage,
                      lastMessageTime: lastMessageTime,
                      profileImageUrl: profileImageUrl,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUnJoinedGroups() {
    List<Map<String, dynamic>> groups = provider.unJoinedGroups;
    if(groups.isEmpty){
      return Center(
        child: Text("No Un Joined Groups Found"),
      );
    }
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (BuildContext context, int index) {
        var room = groups[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.2),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20.0),
            title: Text(
              room['name'] ?? "Untitled Room",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            subtitle: Text("Room ID: ${room['id']}", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
            trailing: ElevatedButton(
              onPressed: () {
                provider.joinGroup(room['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors .blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              ),
              child: Text("Join", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            onTap: () {
              // Optionally, navigate to the room's chat screen or show group details
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupChatHomeProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Group Chats',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 24,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.blueAccent,
            elevation: 0,
            actions: provider.isAdmin ? [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateRoomPage(),
                    ),
                  );
                },
              ),
            ] : null,
          ),
          body: provider.selectedIndex == 0
              ? _buildJoinedGroups()  // Display joined groups
              : _buildUnJoinedGroups(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: provider.selectedIndex,
            onTap: provider.setSelectedIndex,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Joined Groups',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                label: 'Unjoined Groups',
              ),
            ],
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 5,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}