import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/leaveforms/leaveapplication.dart';
import 'package:findany_flutter/leaveforms/leaveformprovider.dart';
import 'package:findany_flutter/leaveforms/leavefromdetailsshow.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class LeaveFormHome extends StatefulWidget {
  @override
  _LeaveFormHomeState createState() => _LeaveFormHomeState();
}

class _LeaveFormHomeState extends State<LeaveFormHome> {
  final _leaveDetailsController = TextEditingController();

  Utils utils = Utils();
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();
  FireStoreService fireStoreService = FireStoreService();
  LoadingDialog loadingDialog = LoadingDialog();

  Future<void> leaveFormApply() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LeaveApplicationForm()),
    );
  }

  Future<void> getLeaveDetails() async {
    loadingDialog.showDefaultLoading("Getting Leave Data...");

    String uid = utils.getCurrentUserUID();
    DocumentReference documentReference = FirebaseFirestore.instance.doc("/UserDetails/$uid/LeaveForms/LeaveApplications");
    Map<String, dynamic>? data = await fireStoreService.getDocumentDetails(documentReference);

    final leaveFormProvider = Provider.of<LeaveFormProvider>(context, listen: false);

    List<Map<String, dynamic>> allData = [];

    if (data != null) {
      for (var entry in data.entries) {
        DocumentReference ref = entry.value as DocumentReference;
        DocumentSnapshot doc = await ref.get();
        allData.add({doc.id: doc.data()});
      }

      allData.sort((a, b) {
        final idA = a.keys.first;
        final idB = b.keys.first;
        return idB.compareTo(idA);
      });
    }

    leaveFormProvider.addLeaveData(allData);
    print("All Data: $allData");
    loadingDialog.dismiss();
  }



  @override
  void initState() {
    super.initState();
    getLeaveDetails();
  }

  @override
  Widget build(BuildContext context) {
    final leaveFormProvider = Provider.of<LeaveFormProvider>(context);
    final leaveData = leaveFormProvider.leaveData;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Form'),
      ),
      body: user == null
          ? Center(child: Text('Please log in to view your leave history'))
          : leaveData.isEmpty
          ? Center(child: Text('No leave forms found.'))
          : ListView.builder(
        itemCount: leaveData.length,
        itemBuilder: (context, index) {
          final leaveEntry = leaveData[index]; // Map with ID as key and leave details as value
          final leaveId = leaveEntry.keys.first; // Extract the ID
          final leaveDetails = leaveEntry[leaveId] as Map<String, dynamic>; // Extract the details

          final studentId = leaveDetails['studentId'] ?? 'Unknown';
          final fromDate = leaveDetails['fromDate'] ?? 'Unknown';
          final toDate = leaveDetails['toDate'] ?? 'Unknown';
          final reason = leaveDetails['reason'] ?? 'No reason provided';
          final approvalStatus = leaveDetails['finalApproval']?['status'] ?? 'Pending';

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaveFormDetailsShow(index: index),
                ),
              );
            },
            child: Card(
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
                  ],
                ),
              ),
            ),
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
