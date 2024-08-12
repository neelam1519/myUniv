import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:provider/provider.dart';

import '../groupchat/chatting.dart';
import '../provider/group_chat_provider.dart';

class BuildGroupTile extends StatelessWidget {
  final String groupName;
  final String? profileUrl;
  final String lastMessage;
  final String formattedTime;

  const BuildGroupTile({
    super.key,
    required this.groupName,
    required this.profileUrl,
    required this.lastMessage,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: ListTile(
        contentPadding: const EdgeInsets.all(5),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.transparent,
          child: ClipOval(
            child: SizedBox(
              width: 60,
              height: 60,
              child: profileUrl != null && profileUrl!.isNotEmpty
                  ? Image.network(
                      profileUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/groupicon.png',
                          fit: BoxFit.cover,
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      'assets/images/groupicon.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        title: Text(
          groupName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                lastMessage,
                style: const TextStyle(fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formattedTime,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          final onlineUsersRef = rtdb.FirebaseDatabase.instance.ref().child("OnlineUsers/$groupName");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Chatting(
                chatRef: rtdb.FirebaseDatabase.instance.ref().child("Chat/$groupName"),
                onlineUsersRef: onlineUsersRef,
                chatName: groupName,
              ),
            ),
          ).then((_) {
            Provider.of<GroupChatProvider>(context, listen: false).fetchChatGroups();
          });
        },
      ),
    );
  }
}
