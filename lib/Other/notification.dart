import 'package:findany_flutter/Other/addnotification.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    User? user = FirebaseAuth.instance.currentUser;
    String? email = await utils.getCurrentUserEmail();
    String id = utils.removeEmailDomain(email!);
    if (user != null) {
      DocumentReference userRef = FirebaseFirestore.instance.doc('AdminDetails/UniversityNews');
      List<String> admins = await utils.getAdmins(userRef);
      setState(() {
        isAdmin = admins.contains(id);
      });
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

          final List<DocumentSnapshot> documents = snapshot.data!.docs;
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
      floatingActionButton: Visibility(
        visible: isAdmin,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddNotification()),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}