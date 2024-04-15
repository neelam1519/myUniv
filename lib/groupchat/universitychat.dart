import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UniversityChat extends StatefulWidget {
  @override
  _UniversityChatState createState() => _UniversityChatState();
}

class _UniversityChatState extends State<UniversityChat> {
  SharedPreferences sharedPreferences = SharedPreferences();
  FireStoreService fireStoreService = FireStoreService();
  RealTimeDatabase realTimeDatabase = new RealTimeDatabase();
  LoadingDialog loadingDialog = new LoadingDialog();
  Utils utils = new Utils();


  FirebaseStorage _storage = FirebaseStorage.instance;

  late Stream<QuerySnapshot> chattingStream;
  late Stream<QuerySnapshot> typingStream;
  late StreamGroup<QuerySnapshot<Object?>> mergedStream;

  Timer? _typingTimer;

  late ChatUser user = ChatUser(id: '', firstName: '', profileImage: '');
  late List<ChatUser> typingUsers = [];
  List<ChatMessage> messages=[];
  String name = '', email = '', regNo = '', profileUrl = '';


  late List<QuerySnapshot> snapshots = [];

  @override
  void initState() {
    super.initState();
    loadingDialog.showDefaultLoading('Getting Messages...');
    subscribeToUniversityChat();

    chattingStream = FirebaseFirestore.instance.collection('Chatting').orderBy('createdAt', descending: true).snapshots();
    typingStream = FirebaseFirestore.instance.collection('TypingDetails').snapshots();
    //mergedStream = StreamGroup<QuerySnapshot<Object?>>.broadcast([chattingStream, typingStream]);
    loadingDialog.showDefaultLoading('Getting Messages');
    getDetails().then((_) {
      setState(() {
        user = ChatUser(
          id: regNo,
          firstName: name,
          profileImage: profileUrl,
        );
      });
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('University Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chattingStream,
              builder: (context, chattingSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: typingStream,
                  builder: (context, typingSnapshot) {
                    // Handle error states
                    if (chattingSnapshot.hasError) {
                      return Text('Error: ${chattingSnapshot.error}');
                    }
                    if (typingSnapshot.hasError) {
                      return Text('Error: ${typingSnapshot.error}');
                    }

                    if (chattingSnapshot.hasData && typingSnapshot.hasData) {
                      snapshots = [chattingSnapshot.data!, typingSnapshot.data!];
                      final data1 = chattingSnapshot.data!.size;
                      final data2 = typingSnapshot.data!.size;
                      print('Received Data from Chatting: $data1');
                      print('Received Data from Typing: $data2');
                      loadingDialog.dismiss();
                    }

                    if (chattingSnapshot.hasData) {
                      messages = chattingSnapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        int microseconds = int.parse(data['createdAt']);
                        Timestamp timestamp = Timestamp.fromMicrosecondsSinceEpoch(microseconds);
                        DateTime createdAt = timestamp.toDate();
                        return ChatMessage(
                          text: data['Message'],
                          user: ChatUser(
                            id: data['regNo'],
                            firstName: data['Name'],
                          ),
                          createdAt: createdAt,
                        );
                      }).toList();
                    }

                    if (typingSnapshot.hasData) {
                      typingUsers = typingSnapshot.data!.docs
                          .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return ChatUser(
                          id: data['id'],
                          firstName: data['Name'],
                        );
                      }).where((user) => user.id != user.id) // Exclude current user
                          .toList();
                    }


                    print('Messages: ${messages}');
                    print('Typing Users: ${typingUsers}');

                    // Return your widget here
                    return buildDashChat(messages, typingUsers);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDashChat(List<ChatMessage> messages,List<ChatUser> typingUsers) {
      return DashChat(
        currentUser: user,
        onSend: (ChatMessage m) async {
          Map<String, dynamic> messageData = {
            'Message': m.text,
            'regNo': m.user.id,
            'Name': m.user.firstName,
            'createdAt': Timestamp.now().microsecondsSinceEpoch.toString(),
            'profileUrl': profileUrl,
          };
          DocumentReference documentReference = FirebaseFirestore.instance.doc('Chatting/${Timestamp.now().microsecondsSinceEpoch.toString()}');
          fireStoreService.uploadMapDataToFirestore(messageData, documentReference,);
          sendNotification();
        },
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            hintText: 'Type your message...',
            // suffixIcon: IconButton(
            //   icon: Icon(Icons.attach_file), // Choose an appropriate icon
            //   onPressed: () {
            //     pickFile();
            //   },
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
          messageMediaBuilder: (ChatMessage message, ChatMessage? previousMessage, ChatMessage? nextMessage) {
            print("Media message");
            // Return an empty container widget
            return Container();
          },

        ),
        typingUsers: typingUsers,
    );
  }

  Future<void> getDetails() async {
    name = (await sharedPreferences.getSecurePrefsValue('Name'))!;
    email = (await sharedPreferences.getSecurePrefsValue('Email'))!;
    regNo = (await sharedPreferences.getSecurePrefsValue('Registration Number'))!;
    profileUrl = (await sharedPreferences.getSecurePrefsValue('ProfileImageURL'))!; // Retrieve profile URL
    print('Details $name  $email  $regNo  $profileUrl');
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      print('Result: $result');
      if (result != null) {
        print('Paths: ${result.paths}');
        List<String?> paths = result.paths;
        if (paths.isNotEmpty) {
          String? imagePath = paths[0];
          print('Image Path: $imagePath');
          await uploadImageAndStoreUrl(imagePath);
        }
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  Future<void> uploadImageAndStoreUrl(String? imagePath) async {
    loadingDialog.showDefaultLoading('Uploading Files...');
    try {
      if (imagePath != null) {
        String extention = utils.getFileExtension(File(imagePath));
        String timestamp = Timestamp.now().microsecondsSinceEpoch.toString();
        print('Timestamp: $timestamp');
        Reference ref = _storage.ref().child('ChatMedia').child('${utils.getCurrentUserUID()}').child('$timestamp.$extention');
        final UploadTask uploadTask = ref.putFile(File(imagePath));
        final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        print('Download URL: $downloadUrl');

        Map<String,String> uploadData = {'Message':downloadUrl, 'regNo': user.id, 'createdAt': timestamp, 'Name': user.firstName.toString(),'Extension':extention};
        DocumentReference documentReference = FirebaseFirestore.instance.doc('/Chatting/$timestamp');
        fireStoreService.uploadMapDataToFirestore(uploadData, documentReference);
        loadingDialog.dismiss();
      }
      loadingDialog.dismiss();
    } catch (e) {
      print('Error uploading file and storing URL: $e');
      loadingDialog.dismiss();
    }
  }

  Future<void> sendNotification() async {
    DocumentReference tokenRef = FirebaseFirestore.instance.doc('/Tokens/Tokens');
    Map<String, dynamic>? tokens = await fireStoreService.getDocumentDetails(tokenRef);
    if(tokens != null) {
      List<dynamic> tokenValues = tokens.values.toList();
    }
  }

  Future<void> subscribeToUniversityChat() async {
    await FirebaseMessaging.instance.subscribeToTopic('UniversityChat');
  }

}

