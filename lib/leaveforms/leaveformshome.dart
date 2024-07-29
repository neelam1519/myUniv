import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/leaveforms/leaveapplication.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveFormHome extends StatefulWidget {
  @override
  _LeaveFormHomeState createState() => _LeaveFormHomeState();
}

class _LeaveFormHomeState extends State<LeaveFormHome> {
  final _leaveDetailsController = TextEditingController();

  Utils utils = Utils();
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();
  FireStoreService fireStoreService = FireStoreService();

  Future<void> leaveFormApply() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LeaveApplicationForm()),
    );
  }

  Future<Map<String, Map<String, dynamic>>> getLeaveDetails() async {
    String uid = utils.getCurrentUserUID();
    DocumentReference documentReference = FirebaseFirestore.instance.doc("/UserDetails/$uid/LeaveForms/LeaveApplications");
    Map<String, dynamic>? data = await fireStoreService.getDocumentDetails(documentReference);

    Map<String, Map<String, dynamic>> allData = {};

    if (data != null) {
      for (var entry in data.entries) {
        if (entry.value is DocumentReference) {
          DocumentReference leaveFormRef = entry.value;
          Map<String, dynamic>? leaveFormData = await fireStoreService.getDocumentDetails(leaveFormRef);
          if (leaveFormData != null) {
            allData[entry.key] = leaveFormData;
          }
        }
      }
    }
    // Reverse the allData map
    Map<String, Map<String, dynamic>> reversedAllData = Map.fromEntries(allData.entries.toList());

    print("Reversed All Data: $reversedAllData");

    return reversedAllData;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Form'),
      ),
      body: user == null
          ? Center(child: Text('Please log in to view your leave history'))
          : FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: getLeaveDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No leave forms found.'));
          }

          final leaveForms = snapshot.data!.entries.toList().reversed.toList();

          return ListView.builder(
            itemCount: leaveForms.length,
            itemBuilder: (context, index) {
              final leaveForm = leaveForms[index].value;
              final studentId = leaveForm['studentId'] ?? 'Unknown';
              final fromDate = leaveForm['fromDate'] ?? 'Unknown';
              final toDate = leaveForm['toDate'] ?? 'Unknown';
              final reason = leaveForm['reason'] ?? 'No reason provided';
              final approvalStatus = leaveForm['finalApproval']['status'] == true ? 'Approved' : 'Pending';
              final createdAt = leaveForm['createdAt'] != null
                  ? (leaveForm['createdAt'] as Timestamp).toDate()
                  : null;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$studentId', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text('From: $fromDate  To: $toDate'),
                      Text('Reason: $reason'),
                      Text('Approval Status: $approvalStatus'),
                      if (createdAt != null)
                        Text('Submitted on ${createdAt.toLocal().toString().split(' ')[0]} at ${createdAt.toLocal().hour}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: leaveFormApply,
        child: Icon(Icons.add),
      ),
    );
  }



  @override
  void dispose() {
    _leaveDetailsController.dispose();
    super.dispose();
  }
}
