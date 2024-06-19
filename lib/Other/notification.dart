import 'package:findany_flutter/Other/addnotification.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHome extends StatefulWidget {
  @override
  _NotificationHomeState createState() => _NotificationHomeState();
}

class _NotificationHomeState extends State<NotificationHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Utils utils = Utils();
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    checkAdminStatus();
  }

  Future<void> checkAdminStatus() async {
    String? email = await utils.getCurrentUserEmail();
    if (email != null) {
      String id = utils.removeEmailDomain(email);
      DocumentReference userRef = _firestore.doc('AdminDetails/Notifications');
      List<String> admins = await utils.getAdmins(userRef);
      if (mounted) {
        setState(() {
          isAdmin = admins.contains(id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('notifications').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No notifications found.'));
          }

          // Extract and sort documents by integer document ID in descending order
          final List<DocumentSnapshot> documents = snapshot.data!.docs;
          documents.sort((a, b) {
            int idA = int.tryParse(a.id) ?? 0;
            int idB = int.tryParse(b.id) ?? 0;
            return idB.compareTo(idA);
          });

          return ListView.separated(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> data = documents[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? 'No Title'),
                subtitle: Text(data['message'] ?? 'No Message'),
              );
            },
            separatorBuilder: (context, index) {
              return Divider();
            },
          );
        },
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddNotification()),
          );
        },
        child: Icon(Icons.add),
      )
          : null, // Only show the FAB if the user is an admin
    );
  }
}
