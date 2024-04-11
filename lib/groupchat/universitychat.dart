import 'dart:async';
import 'dart:io';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UniversityChat extends StatefulWidget {
  @override
  _UniversityChatState createState() => _UniversityChatState();
}

class _UniversityChatState extends State<UniversityChat> {
  SharedPreferences sharedPreferences = SharedPreferences();
  FireStoreService fireStoreService = FireStoreService();
  RealTimeDatabase realTimeDatabase = new RealTimeDatabase();

  Timer? _typingTimer;

  late ChatUser user;
  late List<ChatUser> typingUsers = [];
  List<ChatMessage> messages=[];
  String name = '', email = '', regNo = '', profileUrl = '';

  @override
  void initState() {
    super.initState();

    getDetails().then((_) {
      setState(() {
        user = ChatUser(
          id: regNo,
          firstName: name,
          profileImage: profileUrl, // Set the profile URL here
        );
      });
    });
  }

  Future<void> getDetails() async {
    name = (await sharedPreferences.getSecurePrefsValue('Name'))!;
    email = (await sharedPreferences.getSecurePrefsValue('Email'))!;
    regNo = (await sharedPreferences.getSecurePrefsValue('Registration Number'))!;
    profileUrl = (await sharedPreferences.getSecurePrefsValue('ProfileImageURL'))!; // Retrieve profile URL
    print('$name  $email  $regNo  $profileUrl');
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('University Chat'),
      ),
      body: Column(
        children: [
          // StreamBuilder for chatting
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Chatting').orderBy('createdAt', descending: true).snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> chatSnapshot) {
              if (chatSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${chatSnapshot.error}'),
                );
              }
              if (chatSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              List<ChatMessage> messages = chatSnapshot.data!.docs.map((DocumentSnapshot doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                return ChatMessage(
                  text: data['Message'],
                  user: ChatUser(id: data['regNo'], firstName: data['Name'], profileImage: data['profileUrl']),
                  createdAt: (data['createdAt'] as Timestamp).toDate(),
                );
              }).toList();

              return Expanded(
                child: buildDashChat(messages, typingUsers),
              );
            },
          ),
          // StreamBuilder for typing details
          // StreamBuilder<QuerySnapshot>(
          //   stream: FirebaseFirestore.instance.collection('TypingDetails').snapshots(),
          //   builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> typingSnapshot) {
          //     if (typingSnapshot.hasError) {
          //       return Center(
          //         child: Text('Error: ${typingSnapshot.error}'),
          //       );
          //     }
          //     if (typingSnapshot.connectionState == ConnectionState.waiting) {
          //       return SizedBox(); // Return an empty SizedBox when waiting
          //     }
          //
          //     typingSnapshot.data!.docs.forEach((DocumentSnapshot document) {
          //       Map<String, dynamic> data = document.data() as Map<String, dynamic>;
          //       ChatUser chatUser = ChatUser(id: data['id'], firstName: data['Name']);
          //       typingUsers.add(chatUser);
          //     });
          //
          //     return SizedBox(); // Return an empty SizedBox since we only want to rebuild on changes
          //   },
          // ),
        ],
      ),
    );
  }


  Widget buildDashChat(List<ChatMessage> messages, List<ChatUser> typingUsers) {
    print('Build DashChat is Running $typingUsers');
    return DashChat(
      currentUser: user,
      onSend: (ChatMessage m) async {
        Map<String, dynamic> messageData = {
          'Message': m.text,
          'regNo': m.user.id,
          'Name': m.user.firstName,
          'createdAt': Timestamp.fromDate(m.createdAt),
          'profileUrl': profileUrl,
        };
        DocumentReference documentReference = FirebaseFirestore.instance.doc(
          'Chatting/${DateTime.now().millisecondsSinceEpoch}',
        );
        fireStoreService.uploadMapDataToFirestore(
          messageData,
          documentReference,
        );
      },
      inputOptions: InputOptions(
        inputDecoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          hintText: 'Type your message...',
          // suffixIcon: IconButton(
          //   icon: Icon(Icons.image),
          //   onPressed: () {},
          // ),
        ),
        onTextChange: (String value) async {
          DocumentReference documentReference =
          FirebaseFirestore.instance.doc('TypingDetails/${user.id}');
          _typingTimer?.cancel();
          _typingTimer = Timer(Duration(seconds: 1), () {
            print('User stopped typing');
            fireStoreService.deleteDocument(documentReference);
          });

          Map<String, String> data = {'id': user.id, 'Name': user.firstName!};
          fireStoreService.uploadMapDataToFirestore(data, documentReference);
        },
      ),
      messages: messages,
      messageOptions: MessageOptions(
        messagePadding: EdgeInsets.all(10),
        showTime: true,
        messageTimeBuilder: (ChatMessage chatMessage, bool isOwnMessage) {
          return Padding(
            padding: EdgeInsets.only(left: 40.0),
            child: Text(
              '${chatMessage.createdAt.hour}:${chatMessage.createdAt.minute}',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 6.0,
              ),
            ),
          );
        },
      ),
      typingUsers: typingUsers,
    );
  }


}
