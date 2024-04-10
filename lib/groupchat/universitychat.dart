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
  TextEditingController textEditingController = TextEditingController();
  late final InputDecoration? inputDecoration;
  late final bool alwaysShowSend;

  Timer? _typingTimer;


  late ChatUser user;
  late List<ChatUser>? typingUsers = [];
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

    //typingUsers!.add(user);
  }

  Future<String> uploadImageToFirestore(File imageFile) async {
    String imagePath = 'profile_images/${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      await FirebaseStorage.instance.ref(imagePath).putFile(imageFile);
      String downloadUrl = await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image to Firestore: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('University Chat'),
      ),
      body: FutureBuilder(
        future: getDetails(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Chatting').orderBy('createdAt', descending: true).snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                List<ChatMessage> messages = snapshot.data!.docs.map((DocumentSnapshot doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return ChatMessage(
                    text: data['Message'],
                    user: ChatUser(id: data['regNo'], firstName: data['Name'], profileImage: data['profileUrl']),
                    createdAt: (data['createdAt'] as Timestamp).toDate(),
                  );
                }).toList();

                return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('TypingDetails').snapshots(),
                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    List<ChatUser> chatUsersList = [];

                    snapshot.data!.docs.forEach((DocumentSnapshot document) {
                      Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                      ChatUser chatUser = ChatUser(id: data['id'], firstName: data['firstName']);
                      if (chatUser.id != user.id) {
                        chatUsersList.add(chatUser);
                      }
                    });

                    typingUsers = chatUsersList;
                    print('TypingUsers: $typingUsers');



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
                        DocumentReference documentReference = FirebaseFirestore.instance.doc('Chatting/${DateTime.now().millisecondsSinceEpoch}');
                        fireStoreService.uploadMapDataToFirestore(messageData, documentReference);
                      },
                      messages: messages,
                      typingUsers: typingUsers,
                      inputOptions: InputOptions(
                        inputDecoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            hintText: 'Type your message...',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.attach_file),
                              onPressed: () {

                              },
                            ),
                          ),
                          onTextChange: (String value) async {
                            DocumentReference documentReference = FirebaseFirestore.instance.doc('TypingDetails/${user.id}');

                            _typingTimer?.cancel();
                            _typingTimer = Timer(Duration(seconds: 1), () {
                              print('User stopped typing');
                              fireStoreService.deleteDocument(documentReference);
                            });

                            Map<String,String> data= {'id':user.id,'Name':user.firstName!};
                            fireStoreService.uploadMapDataToFirestore(data, documentReference);
                          }
                      ),
                      messageOptions: MessageOptions(
                        messagePadding: EdgeInsets.all(10),
                        showTime: true,
                        messageTimeBuilder: (ChatMessage chatMessage, bool isOwnMessage) {
                          return Padding(
                            padding: EdgeInsets.only(left: 40.0),
                            child: Text('${chatMessage.createdAt.hour}:${chatMessage.createdAt.minute}',
                              style: TextStyle(color: Colors.grey, fontSize: 6.0,),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
