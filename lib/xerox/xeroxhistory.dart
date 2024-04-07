import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/xerox/xeroxdetailsview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../Firebase/firestore.dart';
import '../utils/utils.dart';

class XeroxHistory extends StatefulWidget {
  @override
  _XeroxHistoryState createState() => _XeroxHistoryState();
}

class _XeroxHistoryState extends State<XeroxHistory> {
  Utils utils = new Utils();
  FireStoreService fireStoreService = new FireStoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xerox History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<DocumentSnapshot> documents = snapshot.data!.docs;
            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> data = documents[index].data() as Map<String, dynamic>;
                return GestureDetector(
                  child: Card(
                    child: ListTile(
                      title: Text(data['Name'] ?? ''),
                      subtitle: Text('Date: ${data['Date']} | Pages: ${data['No of Pages']}'),
                      onTap: () {
                        // Handle onTap event
                        try {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => XeroxDetailView(data: data),
                            ),
                          );
                        } catch (e) {
                          print('Navigation error: $e');
                        }
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Stream<QuerySnapshot> getHistoryStream() {
    CollectionReference userCollRef = FirebaseFirestore.instance.collection('UserDetails/${utils.getCurrentUserUID()}/XeroxHistory/');
    return userCollRef.snapshots();
  }
}
