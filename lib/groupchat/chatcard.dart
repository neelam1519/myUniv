import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatCard extends StatelessWidget {
  final String chatName;
  final String lastMessage;
  final DateTime lastMessageTime; // This is a DateTime object
  final String profileImageUrl;

  ChatCard({
    required this.chatName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.profileImageUrl,
  });

  String _formatLastMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inDays == 0) {
      // Today
      return DateFormat('h:mm a').format(messageTime); // e.g., 3:45 PM
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday ${DateFormat('h:mm a').format(messageTime)}'; // e.g., Yesterday 3:45 PM
    } else if (difference.inDays < 7) {
      // This week
      return '${DateFormat.E().format(messageTime)} ${DateFormat('h:mm a').format(messageTime)}'; // e.g., Mon 3:45 PM
    } else {
      // Last week (or older)
      return DateFormat.yMMMd().add_jm().format(messageTime); // e.g., Dec 29, 2024 3:45 PM
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(profileImageUrl),
              radius: 30,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis, // Handles long messages
                          maxLines: 1, // Ensures the message stays in one line
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        _formatLastMessageTime(lastMessageTime), // Display formatted time
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
