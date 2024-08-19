
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../provider/group_chat_provider.dart';
import '../utils/build_group_tile.dart';

class GroupChatHome extends StatelessWidget {
  const GroupChatHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroupChatProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Group Chats', style: GoogleFonts.dosis(
            fontWeight: FontWeight.w700, fontSize: 22, color: Colors.black87,
          ),),
        ),
        body: Consumer<GroupChatProvider>(
          builder: (context, provider, child) {
            if (provider.chatGroups.isEmpty) {
              provider.fetchChatGroups();
            }
            return ListView(
              children: provider.chatGroups.map((group) {
                return BuildGroupTile(
                  groupName: group['groupName'],
                  profileUrl: group['profileUrl'],
                  lastMessage: group['lastMessage'],
                  formattedTime: group['formattedTime'],
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
