import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'creategroup.dart';

class GroupChatHome extends StatefulWidget {
  @override
  _GroupChatHomeState createState() => _GroupChatHomeState();
}

class _GroupChatHomeState extends State<GroupChatHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Chat'), // Set the title of the app bar
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection('GroupChats').get(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(), // Show a loading indicator while data is being fetched
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'), // Show an error message if data fetching fails
            );
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(data['ProfileUrl'] ?? ''), // Use image URL from Firestore
                  ),
                  title: Text(data['GroupName'] ?? ''), // Use group name from Firestore
                  onTap: () {
                    // Handle tap on the card
                    // For example, navigate to chat room for this group
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show bottom sheet with options
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Container(
                constraints: BoxConstraints(maxHeight: 300), // Set a maximum height for the container
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.group),
                      title: Text('Create Group Chat'),
                      onTap: () {
                        // Handle create group chat option
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateGroupChat()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.handshake),
                      title: Text('Join the Chat'),
                      onTap: () {
                        // Handle create group chat option
                        Navigator.pop(context);
                        // Add your logic to create a group chat
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.cancel),
                      title: Text('Cancel'),
                      onTap: () {
                        // Handle cancel option
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Icon(Icons.add), // Add a chat icon to the button
      ),
    );
  }
}
