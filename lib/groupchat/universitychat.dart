
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:url_launcher/url_launcher.dart';

import '../provider/universitychat_provider.dart';
import 'package:provider/provider.dart';

class UniversityChat extends StatefulWidget {
  static bool isChatOpen = false;

  const UniversityChat({super.key});

  @override
  _UniversityChatState createState() => _UniversityChatState();
}

class _UniversityChatState extends State<UniversityChat> {
  @override
  void initState() {
    super.initState();
    UniversityChat.isChatOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<UniversityChatProvider>(context, listen: false);
      chatProvider.chatRef = rtdb.FirebaseDatabase.instance.ref().child("chats");
      chatProvider.onlineUsersRef = rtdb.FirebaseDatabase.instance.ref().child("onlineUsers");
      chatProvider.initializeUser().then((_) {
        chatProvider.listenForNewMessages();
        chatProvider.trackOnlineUsers();
        chatProvider.setUserOnline();
      });
    });
  }

  @override
  void dispose() {
    final chatProvider = Provider.of<UniversityChatProvider>(context, listen: false);
    chatProvider.messageSubscription.cancel();
    chatProvider.onlineUsersSubscription.cancel();
    chatProvider.setUserOffline();
    UniversityChat.isChatOpen = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('University Chat'),
        actions: [
          Consumer<UniversityChatProvider>(
            builder: (context, chatProvider, child) {
              return chatProvider.onlineUsersCount > 0
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 12),
                    const SizedBox(width: 5),
                    Text('${chatProvider.onlineUsersCount}'),
                  ],
                ),
              )
                  : Container();
            },
          ),
        ],
      ),
      body: Consumer<UniversityChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!chatProvider.isInitialLoadComplete) {
            return const Center(child: CircularProgressIndicator());
          }
          if (chatProvider.messages.isEmpty) {
            return const Center(child: Text('No messages found'));
          }
          return DashChat(
            currentUser: chatProvider.user!,
            onSend: chatProvider.handleSend,
            messages: chatProvider.messages,
            messageListOptions: MessageListOptions(
              onLoadEarlier: chatProvider.loadMoreMessages,
            ),
            inputOptions: const InputOptions(),
            messageOptions: MessageOptions(
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
          );
        },
      ),
    );
  }
}
