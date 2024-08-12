// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:findany_flutter/Firebase/firestore.dart';
// import 'package:findany_flutter/utils/sharedpreferences.dart';
// import 'package:findany_flutter/utils/utils.dart';
// import 'package:flutter/material.dart';
// import 'chatting.dart';
// import 'package:firebase_database/firebase_database.dart' as rtdb;
// import 'package:intl/intl.dart';
//
// class GroupChatHome extends StatefulWidget {
//   const GroupChatHome({super.key});
//
//   @override
//   State<GroupChatHome> createState() => _GroupChatHomeState();
// }
//
// class _GroupChatHomeState extends State<GroupChatHome> {
//   bool _shouldRefresh = true;
//   SharedPreferences sharedPreferences = SharedPreferences();
//   FireStoreService fireStoreService = FireStoreService();
//   Utils utils = Utils();
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_shouldRefresh) {
//       setState(() {
//         _shouldRefresh = false;
//       });
//     }
//   }
//
//   @override
//   void didUpdateWidget(covariant GroupChatHome oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (_shouldRefresh) {
//       setState(() {
//         _shouldRefresh = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (_shouldRefresh) {
//         setState(() {
//           _shouldRefresh = false;
//         });
//       }
//     });
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Group Chats'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('ChatGroups').snapshots(),
//         builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }
//           if (snapshot.hasError) {
//             return Center(
//               child: Text('Error: ${snapshot.error}'),
//             );
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text('No groups found'),
//             );
//           }
//
//           List<Future<Map<String, dynamic>?>> chatFutures = snapshot.data!.docs.map((DocumentSnapshot document) async {
//             Map<String, dynamic> data = document.data() as Map<String, dynamic>;
//             String groupName = data['GroupName'];
//
//             if (groupName == 'App Testing') {
//               return null;
//             }
//
//             rtdb.DatabaseReference chatRef = rtdb.FirebaseDatabase.instance.ref().child("Chat/$groupName");
//
//             if(groupName != 'University Chat') {
//               isFirstTime(groupName);
//             }
//
//             rtdb.DataSnapshot chatSnapshot = await chatRef.orderByKey().limitToLast(1).get();
//             if (chatSnapshot.value != null) {
//               Map lastMessageMap = chatSnapshot.value as Map;
//               Map<String, dynamic> lastMessageData = Map<String, dynamic>.from(lastMessageMap.values.first);
//               String lastMessage = lastMessageData['text'] ?? '';
//               String createdAt = lastMessageData['createdAt'] ?? '';
//
//               DateTime createdAtDate = DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now();
//               String formattedTime = _formatTime(createdAtDate);
//
//               return {
//                 'groupName': groupName,
//                 'profileUrl': data['ProfileUrl'],
//                 'lastMessage': lastMessage,
//                 'formattedTime': formattedTime,
//                 'createdAt': createdAtDate,
//               };
//             } else {
//               return {
//                 'groupName': groupName,
//                 'profileUrl': data['ProfileUrl'],
//                 'lastMessage': '',
//                 'formattedTime': '',
//                 'createdAt': DateTime.fromMillisecondsSinceEpoch(0),
//               };
//             }
//           }).toList();
//
//           return FutureBuilder<List<Map<String, dynamic>?>>(
//             future: Future.wait(chatFutures),
//             builder: (context, futureSnapshot) {
//               if (futureSnapshot.connectionState == ConnectionState.waiting) {
//                 return Center(
//                   child: CircularProgressIndicator(),
//                 );
//               }
//               if (futureSnapshot.hasError) {
//                 return Center(
//                   child: Text('Error: ${futureSnapshot.error}'),
//                 );
//               }
//               if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
//                 return Center(
//                   child: Text('No groups found'),
//                 );
//               }
//
//               List<Map<String, dynamic>> chatGroups = futureSnapshot.data!
//                   .where((group) => group != null)
//                   .map((group) => group!)
//                   .toList();
//
//               chatGroups.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
//
//               return ListView(
//                 children: chatGroups.map((group) {
//                   return _buildGroupTile(
//                     group['groupName'],
//                     group['profileUrl'],
//                     group['lastMessage'],
//                     group['formattedTime'],
//                   );
//                 }).toList(),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Future<void> isFirstTime(String chatName) async{
//     chatName = chatName.replaceAll(" ", "");
//     String key = "${chatName}isFirstTime";
//     print('key $key');
//     bool value = await utils.checkFirstTime(key);
//     print('isFirstTime: $value');
//     if(value){
//       subscribeToChat(chatName);
//       Map<String,dynamic> values = {"${chatName}isFirstTime": false};
//       sharedPreferences.storeMapValuesInSecureStorage(values);
//     }else{
//       print('$chatName is already a member');
//     }
//   }
//
//   void subscribeToChat(String chatName) async {
//     chatName = chatName.replaceAll(" ", "");
//     DocumentReference userRef = FirebaseFirestore.instance.doc('UserDetails/${utils.getCurrentUserUID()}');
//     String regNo = await sharedPreferences.getDataFromReference(userRef, "Registration Number");
//     DocumentReference groupRef = FirebaseFirestore.instance.doc('ChatGroups/$chatName');
//     Map<String, dynamic> data = {"MEMBERS": FieldValue.arrayUnion([regNo])};
//     fireStoreService.uploadMapDataToFirestore(data, groupRef);
//   }
//
//   String _formatTime(DateTime dateTime) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final yesterday = today.subtract(Duration(days: 1));
//     final twoDaysAgo = today.subtract(Duration(days: 2));
//
//     if (dateTime.isAfter(today)) {
//       return DateFormat('hh:mm a').format(dateTime);
//     } else if (dateTime.isAfter(yesterday)) {
//       return 'Yesterday, ${DateFormat('hh:mm a').format(dateTime)}';
//     } else if (dateTime.isAfter(twoDaysAgo)) {
//       return DateFormat('MM/dd/yyyy, hh:mm a').format(dateTime);
//     } else {
//       return DateFormat('MM/dd/yyyy, hh:mm a').format(dateTime);
//     }
//   }
//
//   Widget _buildGroupTile(String groupName, String? profileUrl, String lastMessage, String formattedTime) {
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//       child: ListTile(
//         contentPadding: EdgeInsets.all(5),
//         leading: CircleAvatar(
//           radius: 30,
//           backgroundColor: Colors.transparent,
//           child: ClipOval(
//             child: SizedBox(
//               width: 60,
//               height: 60,
//               child: profileUrl != null && profileUrl.isNotEmpty
//                   ? Image.network(
//                 profileUrl,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) {
//                   return Image.asset(
//                     'assets/images/groupicon.png',
//                     fit: BoxFit.cover,
//                   );
//                 },
//                 loadingBuilder: (context, child, progress) {
//                   if (progress == null) return child;
//                   return Center(
//                     child: CircularProgressIndicator(
//                       value: progress.expectedTotalBytes != null
//                           ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
//                           : null,
//                     ),
//                   );
//                 },
//               )
//                   : Image.asset(
//                 'assets/images/groupicon.png',
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//         ),
//         title: Text(
//           groupName,
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         subtitle: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 lastMessage,
//                 style: TextStyle(fontSize: 15),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             SizedBox(width: 10), // Adds a bit of space between the message and the time
//             Text(
//               formattedTime,
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//           ],
//         ),
//         onTap: () {
//           rtdb.DatabaseReference onlineUsersRef = rtdb.FirebaseDatabase.instance.ref().child("OnlineUsers/$groupName");
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => Chatting(
//                 chatRef: rtdb.FirebaseDatabase.instance.ref().child("Chat/$groupName"),
//                 onlineUsersRef: onlineUsersRef,
//                 chatName: groupName,
//               ),
//             ),
//           ).then((_) {
//             setState(() {
//               _shouldRefresh = true;
//             });
//           });
//         },
//       ),
//     );
//   }
//
// }

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

// Widget _buildGroupTile(BuildContext context, String groupName, String? profileUrl, String lastMessage, String formattedTime) {
//   return Card(
//     margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//     child: ListTile(
//       contentPadding: const EdgeInsets.all(5),
//       leading: CircleAvatar(
//         radius: 30,
//         backgroundColor: Colors.transparent,
//         child: ClipOval(
//           child: SizedBox(
//             width: 60,
//             height: 60,
//             child: profileUrl != null && profileUrl.isNotEmpty
//                 ? Image.network(
//               profileUrl,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) {
//                 return Image.asset(
//                   'assets/images/groupicon.png',
//                   fit: BoxFit.cover,
//                 );
//               },
//               loadingBuilder: (context, child, progress) {
//                 if (progress == null) return child;
//                 return Center(
//                   child: CircularProgressIndicator(
//                     value: progress.expectedTotalBytes != null
//                         ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
//                         : null,
//                   ),
//                 );
//               },
//             )
//                 : Image.asset(
//               'assets/images/groupicon.png',
//               fit: BoxFit.cover,
//             ),
//           ),
//         ),
//       ),
//       title: Text(
//         groupName,
//         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//       subtitle: Row(
//         children: [
//           Expanded(
//             child: Text(
//               lastMessage,
//               style: const TextStyle(fontSize: 15),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           const SizedBox(width: 10),
//           Text(
//             formattedTime,
//             style: const TextStyle(fontSize: 12, color: Colors.grey),
//           ),
//         ],
//       ),
//       onTap: () {
//         final onlineUsersRef = rtdb.FirebaseDatabase.instance.ref().child("OnlineUsers/$groupName");
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => Chatting(
//               chatRef: rtdb.FirebaseDatabase.instance.ref().child("Chat/$groupName"),
//               onlineUsersRef: onlineUsersRef,
//               chatName: groupName,
//             ),
//           ),
//         ).then((_) {
//           Provider.of<GroupChatProvider>(context, listen: false).fetchChatGroups();
//         });
//       },
//     ),
//   );
// }
}
