import 'dart:io';

import 'package:findany_flutter/groupchat/groupchathome.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

import 'groupchathome_provider.dart'; // Import Firebase storage

class CreateRoomPage extends StatefulWidget {
  @override
  _CreateRoomPageState createState() => _CreateRoomPageState();
}


class _CreateRoomPageState extends State<CreateRoomPage> {
  final TextEditingController _roomNameController = TextEditingController();
  bool _addAllUsers = false;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();
  LoadingDialog loadingDialog = LoadingDialog();


  // Pick image from gallery
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Upload the image to Firebase Storage
      try {
        String fileName = pickedFile.name;
        Reference storageRef = FirebaseStorage.instance.ref().child('room_images/$fileName');
        UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _imageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> createRoom() async {
    final provider = Provider.of<GroupChatHomeProvider>(context, listen: false);

    loadingDialog.showDefaultLoading('Creating Room...');
    if (_roomNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room name is required.')),
      );
      loadingDialog.dismiss();
      return;
    }

    try {
      // Get the current logged-in user
      final currentUser = FirebaseAuth.instance.currentUser;

      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get();

      if (!adminSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin details not found.')),
        );
        loadingDialog.dismiss();
        return;
      }

      // Fetch all users if "Add All Users" is selected
      final List<types.User> users = _addAllUsers
          ? (await FirebaseFirestore.instance.collection('users').get())
          .docs
          .map((doc) => types.User(
        id: doc.id,
        firstName: doc.data()['firstName'] ?? '',
        lastName: doc.data()['lastName'] ?? '',
        imageUrl: doc.data()['imageUrl'],
        role: types.Role.user,
      )).toList() : [];


      print("Users: $users");

      // Create the group room
      await FirebaseChatCore.instance.createGroupRoom(
        name: _roomNameController.text.trim(),
        imageUrl: _imageUrl ?? "", // Use the uploaded image URL
        users: users,
        metadata: {
          "createdAt": DateTime.now().toIso8601String(), // Use ISO8601 string
          "updatedAt": DateTime.now().toIso8601String(), // Use ISO8601 string
        },
        creatorRole: types.Role.admin,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room created successfully!')),
      );

      loadingDialog.dismiss();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GroupChatHome(),
        ),
      );    } catch (e) {
      loadingDialog.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating room: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Room'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Room Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _roomNameController,
              decoration: InputDecoration(
                labelText: 'Room Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Pick Room Image'),
                ),
                SizedBox(width: 10),
                if (_imageUrl != null)
                  Image.network(_imageUrl!, width: 50, height: 50),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Add All Users to the Room'),
              subtitle: const Text('Includes all registered users in this group'),
              value: _addAllUsers,
              onChanged: (value) {
                setState(() {
                  _addAllUsers = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: createRoom,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Create Room', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
