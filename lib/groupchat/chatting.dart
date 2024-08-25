import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/provider/chatting_provider.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Chatting extends StatefulWidget {
  static bool isChatOpen = false;
  static String groupName = "";

  final rtdb.DatabaseReference chatRef;
  final rtdb.DatabaseReference onlineUsersRef;
  final String chatName;

  const Chatting({
    super.key,
    required this.chatRef,
    required this.onlineUsersRef,
    required this.chatName,
  });

  @override
  State<Chatting> createState() => _ChattingState();
}

class _ChattingState extends State<Chatting> {
  ChatProvider? chatProvider;

  @override
  void initState() {
    print("Chatting is opened");
    super.initState();
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatProvider?.chatRef = widget.chatRef;
      chatProvider?.onlineUsersRef = widget.onlineUsersRef;
      chatProvider?.chatName = widget.chatName.replaceAll(" ", "");
      Chatting.groupName = widget.chatName;
      Chatting.isChatOpen = true;
      chatProvider?.initializeUser().then((_) {
        if (chatProvider?.chatName == "UniversityChat") {
          chatProvider?.isMember = true;
        } else {
          chatProvider
            ?..checkMembershipStatus()
            ..isFirstTime();
        }
        chatProvider
          ?..fetchRestrictedWords()
          ..listenForNewMessages()
          ..trackOnlineUsers()
          ..setUserOffline();
      });
    });
  }

  @override
  void dispose() {
    Chatting.isChatOpen = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chattingProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.chatName),
            actions: [
              if (chatProvider?.chatName != "UniversityChat")
                IconButton(
                  icon: Icon(
                    chattingProvider.isMember ? Icons.group_remove : Icons.group_add,
                    color: chattingProvider.isMember ? Colors.red : Colors.green,
                  ),
                  onPressed: () async {
                    String regNo = await chattingProvider.sharedPreferences
                        .getDataFromReference(chattingProvider.userRef!, "Registration Number");
                    DocumentReference groupRef =
                        FirebaseFirestore.instance.doc('ChatGroups/${chattingProvider.chatName}');

                    if (chattingProvider.isMember) {
                      DocumentSnapshot groupSnapshot = await groupRef.get();
                      if (groupSnapshot.exists) {
                        Map<String, dynamic>? groupData = groupSnapshot.data() as Map<String, dynamic>?;
                        if (groupData != null && groupData.containsKey('MEMBERS')) {
                          List<dynamic> members = List.from(groupData['MEMBERS']);
                          members.remove(regNo);
                          await groupRef.update({'MEMBERS': members});
                          print('Removed $regNo from MEMBERS list');
                        } else {
                          print('MEMBERS field does not exist in the group document');
                        }
                      } else {
                        print('Group document does not exist');
                      }
                      chattingProvider.utils.showToastMessage('Removed from the group');
                      print('Removed from the group');
                    } else {
                      Map<String, dynamic> data = {
                        "MEMBERS": FieldValue.arrayUnion([regNo])
                      };
                      chattingProvider.fireStoreService.uploadMapDataToFirestore(data, groupRef);
                      chattingProvider.utils.showToastMessage('Added to the group');
                      print('Added to the group');
                    }
                    chattingProvider.isMember = !chatProvider!.isMember;
                  },
                ),
              if (chattingProvider.onlineUsersCount > 0)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.green, size: 12),
                      const SizedBox(width: 5),
                      Text('${chattingProvider.onlineUsersCount}'),
                    ],
                  ),
                ),
            ],
          ),
          body: chattingProvider.user == null
              ? const Center(child: CircularProgressIndicator())
              : !chattingProvider.isInitialLoadComplete
                  ? const Center(child: CircularProgressIndicator())
                  : DashChat(
                      currentUser: chattingProvider.user!,
                      onSend: chattingProvider.handleSend,
                      messages: chattingProvider.messages,
                      readOnly: !chattingProvider.isMember,
                      messageListOptions: MessageListOptions(
                        onLoadEarlier: chattingProvider.loadMoreMessages,
                      ),
                      inputOptions: const InputOptions(),
                      messageOptions: MessageOptions(
                        showTime: true,
                        parsePatterns: [
                          MatchText(
                            type: ParsedType.URL,
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            onTap: (url) async {
                              if (await canLaunch(url)) {
                                await launch(url);
                              } else {
                                throw 'Could not launch $url';
                              }
                            },
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}
