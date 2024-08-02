import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/leaveforms/leaveformprovider.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../services/pdfscreen.dart';
import 'package:qr_flutter/qr_flutter.dart';


class LeaveFormDetails extends StatefulWidget {
  final int index;
  final String sectionYear;
  final String branch;
  final String stream;
  final String faYear;


  LeaveFormDetails({required this.index, required this.sectionYear, required this.branch, required this.stream, required this.faYear});

  @override
  _LeaveFormDetailsState createState() => _LeaveFormDetailsState();
}

class _LeaveFormDetailsState extends State  <LeaveFormDetails> {
  final FireStoreService fireStoreService = FireStoreService();
  LoadingDialog loadingDialog = LoadingDialog();
  Dio dio = Dio();

  String docId="";

  void _updateApprovalStatus(BuildContext context, bool isApproved) {
    loadingDialog.showDefaultLoading('Updating the details');
    final leaveFormProvider = Provider.of<LeaveFormProvider>(context, listen: false);
    final DocumentReference ref = FirebaseFirestore.instance.doc('LeaveForms/$docId');
    CollectionReference collectionReference = FirebaseFirestore.instance.collection("AcademicDetails");
    DocumentReference nextRef = FirebaseFirestore.instance.doc("AcademicDetails/ErrorLeaveForms");

    String role = leaveFormProvider.selectedRole ?? " ";
    print('Reference: ${ref.path}');

    String acceptName = "";
    if (role == "FACULTY ADVISOR") {
      acceptName = "facultyAdvisorApproval";
    } else if (role == "YEAR COORDINATOR") {
      acceptName = "yearCoordinatorApproval";
    } else if (role == "HOD") {
      acceptName = "hodApproval";
    }else if(role =='HOSTEL WARDEN'){
      acceptName = "hostelWardenApproval";
    }

    if (role == "FACULTY ADVISOR") {
      collectionReference = FirebaseFirestore.instance.collection('/AcademicDetails/${widget.faYear}/BRANCHES/${widget.branch}/SPECIALIZATIONS/${widget.stream}/SECTIONS/${widget.sectionYear}/$role LEAVEFORMS');
    } else if (role == 'YEAR COORDINATOR') {
      collectionReference = FirebaseFirestore.instance.collection('/AcademicDetails/${widget.sectionYear}/BRANCHES/${widget.branch}/SPECIALIZATIONS/${widget.stream}/LEAVEFORMS');
    }else if(role == "HOD"){
      collectionReference = FirebaseFirestore.instance.collection('/AcademicDetails/${widget.sectionYear}/BRANCHES/${widget.branch}/LEAVEFORMS');
    }else if(role =="HOSTEL WARDEN"){
      collectionReference = FirebaseFirestore.instance.collection("HostelDetails/BHAGHAT SINGH HOSTEL/LEAVEFORMS");
    }

    List<String> fieldNames = [docId];
    fireStoreService.deleteFieldsFromDocument(collectionReference.doc("PENDING"), fieldNames);
    DocumentReference reference = FirebaseFirestore.instance.doc('LeaveForms/$docId');
    Map<String, dynamic> uploadData = {docId: reference};

    if (role == "FACULTY ADVISOR") {
      nextRef = FirebaseFirestore.instance.doc("AcademicDetails/${widget.faYear}/BRANCHES/${widget.branch}/SPECIALIZATIONS/${widget.stream}/LEAVEFORMS/PENDING");
    } else if (role == "YEAR COORDINATOR") {
      nextRef = FirebaseFirestore.instance.doc("AcademicDetails/${widget.faYear}/BRANCHES/${widget.branch}/LEAVEFORMS/PENDING");
    }else if(role == "HOD"){
      nextRef = FirebaseFirestore.instance.doc("HostelDetails/BHAGHAT SINGH HOSTEL/LEAVEFORMS/PENDING");
    }

    print('Next Ref: ${nextRef.path}');

    if (isApproved) {
      if(role == "HOSTEL WARDEN"){
        ref.update({'$acceptName.status': "APPROVED"});
        ref.update({'finalApproval.status': "APPROVED"});
        fireStoreService.uploadMapDataToFirestore(uploadData, collectionReference.doc("ACCEPTED"));
      }else{
        fireStoreService.uploadMapDataToFirestore(uploadData, collectionReference.doc("ACCEPTED"));
        ref.update({'$acceptName.status': "APPROVED"});
        fireStoreService.uploadMapDataToFirestore(uploadData, nextRef);
      }

    } else {
      fireStoreService.uploadMapDataToFirestore(uploadData, collectionReference.doc("REJECTED"));
      ref.update({'$acceptName.status': "REJECTED"});
      ref.update({'finalApproval.status': "REJECTED"});
    }

    leaveFormProvider.removeLeaveData(widget.index);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isApproved ? 'Leave form accepted' : 'Leave form rejected'),
      ),
    );
    loadingDialog.dismiss();
    Navigator.pop(context);
  }

  Future<void> _downloadAndOpenFile(String url, String filename) async {
    try {
      final dir = await getTemporaryDirectory(); // Get temporary directory
      final filePath = '${dir.path}/FileSelection/$filename'; // Create file path

      final file = File(filePath);

      if (await file.exists()) {
        // File already exists, open it directly
        print('File already exists at $filePath');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFScreen(filePath: filePath, title: filename),
          ),
        );
      } else {
        // File does not exist, download it
        loadingDialog.showDefaultLoading('Downloading...');
        final dio = Dio();

        await dio.download(url, filePath, onReceiveProgress: (received, total) {
          if (total != -1) {
            EasyLoading.showProgress(received / total, status: 'Downloading...');
          }
        });

        EasyLoading.dismiss();
        print('File downloaded to $filePath');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFScreen(filePath: filePath, title: filename),
          ),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      print('Error downloading or opening file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveFormProvider = Provider.of<LeaveFormProvider>(context);
    final List<Map<String, dynamic>> leaveData = leaveFormProvider.leaveData;

    if (widget.index >= leaveData.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Leave Form Details'),
        ),
        body: Center(
          child: Text('Leave form not found.'),
        ),
      );
    }

    final Map<String, dynamic> data = leaveData[widget.index];
    docId = data.keys.first;
    final Map<String, dynamic> leaveDetails = data[docId];

    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Form Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Student ID:', leaveDetails['studentId'] ?? 'N/A'),
                _buildInfoRow('Student Name:', leaveDetails['studentName'] ?? 'N/A'),
                Row(
                  children: [
                    _buildDateInfo('From Date:', leaveDetails['fromDate'] ?? 'N/A'),
                    SizedBox(width: 20),
                    _buildDateInfo('To Date:', leaveDetails['toDate'] ?? 'N/A'),
                  ],
                ),
                Divider(height: 20, thickness: 1),
                _buildInfoRow('Father Mobile:', leaveDetails['fatherMobile'] ?? 'N/A'),
                _buildInfoRow('Alternative Mobile:', leaveDetails['alternativeMobile'] ?? 'N/A'),
                Divider(height: 20, thickness: 1),
                _buildInfoRow('Reason:', leaveDetails['reason'] ?? 'N/A'),
                Divider(height: 20, thickness: 1),
                _buildProofFile(leaveDetails['proofFileUrl'] ?? 'N/A'),
                Divider(height: 20, thickness: 1),
                _buildApprovalRow('Faculty Advisor Approval:', leaveDetails['facultyAdvisorApproval']['status']),
                _buildApprovalRow('Year Coordinator Approval:', leaveDetails['yearCoordinatorApproval']['status']),
                _buildApprovalRow('HOD Approval:', leaveDetails['hodApproval']['status']),
                _buildApprovalRow('Hostel Warden Approval:', leaveDetails['hostelWardenApproval']['status']),
                Divider(height: 20, thickness: 1),
                _buildApprovalRow('Final Approval:', leaveDetails['finalApproval']?['status'], isBold: true),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton('Accept', Colors.green, () => _updateApprovalStatus(context, true)),
                    _buildActionButton('Reject', Colors.red, () => _updateApprovalStatus(context, false)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String date) {
    return Text(
      '$label $date',
      style: TextStyle(fontSize: 16),
    );
  }

  Widget _buildApprovalRow(String label, dynamic status, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Expanded(
            child: Text(
              status,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(text),
    );
  }

  Widget _buildProofFile(String url) {
    if (url == 'N/A' || url.isEmpty) {
      return _buildInfoRow('Proof File URL:', "No Proof Uploaded");
    }
    print('Url: $url');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proof File:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            _downloadAndOpenFile(url, 'proof_file.pdf');
          },
          child: Text(
            'proof_file.pdf',
            style: TextStyle(fontSize: 16, color: Colors.blue, decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

}
