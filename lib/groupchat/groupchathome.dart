import 'package:flutter/material.dart'; // Import the material package for material design widgets

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
      body: Center(
        child: Text('Welcome to Group Chat!'), // Display a welcome message
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
