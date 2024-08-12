import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../Firebase/firestore.dart';
import '../Firebase/realtimedatabase.dart';
import '../Firebase/storage.dart';
import '../utils/sharedpreferences.dart';
import '../utils/utils.dart';

class LeaveApplicationFormProvider with ChangeNotifier {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _fatherMobileController = TextEditingController();
  final TextEditingController _alternativeMobileController = TextEditingController();
  PlatformFile? _selectedFile;

  FireStoreService fireStoreService = FireStoreService();
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();
  FirebaseStorageHelper firebaseStorageHelper = FirebaseStorageHelper();
  Utils utils = Utils();
  SharedPreferences sharedPreferences = SharedPreferences();

  GlobalKey<FormState> get formKey => _formKey;
  TextEditingController get nameController => _nameController;
  TextEditingController get reasonController => _reasonController;
  TextEditingController get fromDateController => _fromDateController;
  TextEditingController get toDateController => _toDateController;
  TextEditingController get fatherMobileController => _fatherMobileController;
  TextEditingController get alternativeMobileController => _alternativeMobileController;
  PlatformFile? get selectedFile => _selectedFile;

  set selectedFile(PlatformFile? file) {
    _selectedFile = file;
    notifyListeners();
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      selectedFile = result.files.first;
    }
  }

  Future<void> uploadFileAndSubmitForm(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String fileUrl = '';
        String? uid = await utils.getCurrentUserUID();
        int count = await realTimeDatabase.incrementValue('/LeaveFormDetails/LeaveFormsCount') ?? 0;
        DocumentReference documentReference = FirebaseFirestore.instance.doc("UserDetails/$uid");
        String regNo = await sharedPreferences.getDataFromReference(documentReference, "Registration Number");
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

        Map<String, dynamic> data = {
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
        Map<String, dynamic> reference = {count.toString(): leaveFormRef};
        fireStoreService.uploadMapDataToFirestore(reference, userRef);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave form submitted successfully')));
        clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in')));
      }
    }
  }

  void clearForm() {
    _nameController.clear();
    _reasonController.clear();
    _fromDateController.clear();
    _toDateController.clear();
    _fatherMobileController.clear();
    _alternativeMobileController.clear();
    selectedFile = null;
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
