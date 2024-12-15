import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';


class CreateRoomPage extends StatefulWidget {
  @override
  _CreateRoomPageState createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final TextEditingController _roomNameController = TextEditingController();
  final List<types.User> _participants = []; // List of participants

  Future<void> createRoom() async {

    await FirebaseChatCore.instance.createGroupRoom(
      name: _roomNameController.text,
      users: _participants,
      creatorRole: types.Role.admin,
      imageUrl: '', // Optional, can be a valid image URL
      metadata: {
        "createdAt": DateTime.now().millisecondsSinceEpoch,
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
      },
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _roomNameController,
              decoration: const InputDecoration(labelText: 'Room Name'),
            ),
            const SizedBox(height: 16),
            // Add participants by user IDs (change the input to be more meaningful)
            TextField(
              decoration: const InputDecoration(labelText: 'Add Participant (Name)'),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  // Ensure each participant has an ID
                  final newUser  = types.User(id: value, firstName: value); // Example user with just a name
                  _participants.add(newUser );
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 16),
            // Display list of added participants (without showing IDs directly)
            Wrap(
              spacing: 8.0,
              children: _participants
                  .map((user) => Chip(label: Text(user.firstName ?? 'Unknown')))
                  .toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: createRoom,
              child: const Text('Create Room'),
            ),
          ],
        ),
      ),
    );
  }
}