// import 'package:findany_flutter/Other/addnotification.dart';
// import 'package:findany_flutter/utils/utils.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class NotificationHome extends StatefulWidget {
//   const NotificationHome({super.key});
//
//   @override
//   State<NotificationHome> createState() => _NotificationHomeState();
// }
//
// class _NotificationHomeState extends State<NotificationHome> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final Utils utils = Utils();
//   bool isAdmin = false;
//
//   @override
//   void initState() {
//     super.initState();
//     checkAdminStatus();
//   }
//
//   Future<void> checkAdminStatus() async {
//     final email = await utils.getCurrentUserEmail();
//     if (email != null) {
//       final id = utils.removeEmailDomain(email);
//       final userRef = _firestore.doc('AdminDetails/Notifications');
//       final admins = await utils.getAdmins(userRef);
//       if (mounted) {
//         setState(() {
//           isAdmin = admins.contains(id);
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notifications'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('notifications').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No notifications found.'));
//           }
//
//           final documents = snapshot.data!.docs;
//           documents.sort((a, b) {
//             final idA = int.tryParse(a.id) ?? 0;
//             final idB = int.tryParse(b.id) ?? 0;
//             return idB.compareTo(idA);
//           });
//
//           return ListView.separated(
//             itemCount: documents.length,
//             itemBuilder: (context, index) {
//               final data = documents[index].data() as Map<String, dynamic>;
//               return ListTile(
//                 title: Text(data['title'] ?? 'No Title'),
//                 subtitle: Text(data['message'] ?? 'No Message'),
//               );
//             },
//             separatorBuilder: (context, index) => const Divider(),
//           );
//         },
//       ),
//       floatingActionButton: isAdmin
//           ? FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const AddNotification()),
//           );
//         },
//         child: const Icon(Icons.add),
//       )
//           : null,
//     );
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/notificationhome_provider.dart';
import 'addnotification.dart';

class NotificationHome extends StatefulWidget {
  const NotificationHome({super.key});

  @override
  State<NotificationHome> createState() => _NotificationHomeState();
}

class _NotificationHomeState extends State<NotificationHome> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<NotificationHomeProvider>().checkAdminStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationHomeProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No notifications found.'));
              }

              final documents = snapshot.data!.docs;
              documents.sort((a, b) {
                final idA = int.tryParse(a.id) ?? 0;
                final idB = int.tryParse(b.id) ?? 0;
                return idB.compareTo(idA);
              });

              return ListView.separated(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final data = documents[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['title'] ?? 'No Title'),
                    subtitle: Text(data['message'] ?? 'No Message'),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
              );
            },
          ),
          floatingActionButton: provider.isAdmin
              ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddNotification()),
              );
            },
            child: const Icon(Icons.add),
          )
              : null,
        );
      },
    );
  }
}
