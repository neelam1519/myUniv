import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/Firebase/storage.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class LeaveApplicationForm extends StatefulWidget {
  @override
  _LeaveApplicationFormState createState() => _LeaveApplicationFormState();
}

class _LeaveApplicationFormState extends State<LeaveApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  final _fatherMobileController = TextEditingController();
  final _alternativeMobileController = TextEditingController();
  PlatformFile? _selectedFile;

  FireStoreService fireStoreService = FireStoreService();
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();
  FirebaseStorageHelper firebaseStorageHelper = FirebaseStorageHelper();
  Utils utils = Utils();
  SharedPreferences sharedPreferences  = SharedPreferences();

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }


  Future<void> _uploadFileAndSubmitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String fileUrl = '';

        String uid = utils.getCurrentUserUID();
        int count = await realTimeDatabase.incrementValue('/LeaveFormDetails/LeaveFormsCount') ?? 0;
        DocumentReference documentReference = FirebaseFirestore.instance.doc("UserDetails/$uid");
        String regNo =await  sharedPreferences.getDataFromReference(documentReference, "Registration Number");
        if (_selectedFile != null) {
          File fileToUpload = File(_selectedFile!.path!);
          String fileName = _selectedFile!.name;
          String filePath = 'LeaveFormFiles/${utils.getTodayDate()}/$count';

          try {
            await FirebaseStorage.instance.ref(filePath).putFile(fileToUpload);
            fileUrl = await FirebaseStorage.instance.ref(filePath).getDownloadURL();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload $fileName')));
            return;
          }
        }

        DocumentReference leaveFormRef = FirebaseFirestore.instance.doc("LeaveForms/$count");
        DocumentReference userRef = FirebaseFirestore.instance.doc("UserDetails/$uid/LeaveForms/LeaveApplications");

        Map<String,dynamic> data = {
          'studentId': regNo,
          'studentName': _nameController.text,
          'reason': _reasonController.text,
          'fromDate': _fromDateController.text,
          'toDate': _toDateController.text,
          'fatherMobile': _fatherMobileController.text,
          'alternativeMobile': _alternativeMobileController.text,
          'proofFileUrl': fileUrl,
          'facultyAdvisorApproval': {'status': false, 'timestamp': null},
          'yearCoordinatorApproval': {'status': false, 'timestamp': null},
          'hodApproval': {'status': false, 'timestamp': null},
          'hostelWardenApproval': {'status': false, 'timestamp': null},
          'finalApproval': {'status': false, 'timestamp': null},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp()
        };

        fireStoreService.uploadMapDataToFirestore(data, leaveFormRef);
        Map<String,dynamic> reference = {count.toString():leaveFormRef};
        fireStoreService.uploadMapDataToFirestore(reference, userRef);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave form submitted successfully')));
        _clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not logged in')));
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _reasonController.clear();
    _fromDateController.clear();
    _toDateController.clear();
    _fatherMobileController.clear();
    _alternativeMobileController.clear();
    setState(() {
      _selectedFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Application Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(labelText: 'Reason'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the reason for leave';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _fromDateController,
                decoration: InputDecoration(labelText: 'From Date (DD-MM-YYYY)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the start date of leave';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _toDateController,
                decoration: InputDecoration(labelText: 'To Date (DD-MM-YYYY)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the end date of leave';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _fatherMobileController,
                decoration: InputDecoration(labelText: "Father's Mobile Number"),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your father's mobile number";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _alternativeMobileController,
                decoration: InputDecoration(labelText: 'Alternative Mobile Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an alternative mobile number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickFile,
                child: Text('Upload Proof'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadFileAndSubmitForm,
                child: Text('Submit Leave Form'),
              ),
              SizedBox(height: 20),
              if (_selectedFile != null)
                ListTile(
                  title: Text(_selectedFile!.name),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _fatherMobileController.dispose();
    _alternativeMobileController.dispose();
    super.dispose();
  }
}
