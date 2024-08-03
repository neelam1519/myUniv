import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/leaveforms/leaveformprovider.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/qrscanner.dart';

class WatchmenLeavehome extends StatefulWidget {
  @override
  _WatchmenhomeState createState() => _WatchmenhomeState();
}

class _WatchmenhomeState extends State<WatchmenLeavehome> {

  LoadingDialog loadingDialog = LoadingDialog();
  FireStoreService fireStoreService = FireStoreService();
  Utils utils = Utils();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getLeaveDetails();
  }


  Future<void> getLeaveDetails() async {
    loadingDialog.showDefaultLoading("Getting Leave Data...");
    DocumentReference documentReference = FirebaseFirestore.instance.doc("/AcademicDetails/WATCHMEN APPROVED FORMS");
    print("Document Reference: $documentReference");
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
  Widget build(BuildContext context) {
    final leaveFormProvider = Provider.of<LeaveFormProvider>(context);
    final leaveData = leaveFormProvider.leaveData;
    print("LeaveData: $leaveData");
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Form'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QRScannerScreen()),
              );
            },
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text('Please log in to view your leave history'))
          : leaveData.isEmpty
          ? Center(child: Text('No leave forms found.'))
          : ListView.builder(
        itemCount: leaveData.length,
        itemBuilder: (context, index) {
          final leaveEntry = leaveData[index]; // Map with ID as key and leave details as value
          final leaveId = leaveEntry.keys.first; //
          print("LeaveEntry: $leaveEntry");
          final leaveDetails = leaveEntry[leaveId] as Map<String, dynamic>; // Extract the details

          final studentId = leaveDetails['studentId'] ?? 'Unknown';
          final fromDate = leaveDetails['fromDate'] ?? 'Unknown';
          final toDate = leaveDetails['toDate'] ?? 'Unknown';
          final reason = leaveDetails['reason'] ?? 'No reason provided';
          final approvalStatus = leaveDetails['finalApproval']?['status'] ?? 'Pending';

          return InkWell(
            onTap: () {
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
    );
  }
}

