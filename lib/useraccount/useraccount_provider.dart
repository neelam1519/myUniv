import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

import '../Firebase/firestore.dart';
import '../utils/LoadingDialog.dart';
import '../utils/sharedpreferences.dart';
import '../utils/utils.dart';

class UserAccountProvider with ChangeNotifier {
  final Utils _utils = Utils();
  final SharedPreferences _sharedPreferences = SharedPreferences();
  final FireStoreService _firebaseService = FireStoreService();
  final LoadingDialog _loadingDialog = LoadingDialog();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? _name;
  String? _regNo;
  String? _email;
  String? _imageUrl;

  bool _showPersonalDetails = true;
  bool _showAcademicDetails = true;
  bool _showHostelDetails = true;
  bool _showFacultyDetails = true;

  String? get name => _name;
  String? get regNo => _regNo;
  String? get email => _email;
  String? get imageUrl => _imageUrl;

  bool get showPersonalDetails => _showPersonalDetails;
  bool get showAcademicDetails => _showAcademicDetails;
  bool get showHostelDetails => _showHostelDetails;
  bool get showFacultyDetails => _showFacultyDetails;

  set name(String? value) {
    _name = value;
    notifyListeners();
  }

  set regNo(String? value) {
    _regNo = value;
    notifyListeners();
  }

  set email(String? value) {
    _email = value;
    notifyListeners();
  }

  set imageUrl(String? value) {
    _imageUrl = value;
    notifyListeners();
  }

  set showPersonalDetails(bool value) {
    _showPersonalDetails = value;
    notifyListeners();
  }

  set showAcademicDetails(bool value) {
    _showAcademicDetails = value;
    notifyListeners();
  }

  set showHostelDetails(bool value) {
    _showHostelDetails = value;
    notifyListeners();
  }

  set showFacultyDetails(bool value) {
    _showFacultyDetails = value;
    notifyListeners();
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      if (result != null && result.paths.isNotEmpty) {
        String? imagePath = result.paths[0];
        await uploadImageAndStoreUrl(imagePath!);
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  Future<void> uploadImageAndStoreUrl(String imagePath) async {
    _loadingDialog.showDefaultLoading('Updating profile');
    try {
      String? uid = await _utils.getCurrentUserUID();
      String extension = _utils.getFileExtension(File(imagePath));
      Reference ref = _storage.ref().child('ProfileImages').child('$uid.$extension');
      final UploadTask uploadTask = ref.putFile(File(imagePath));
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      final Map<String, String> image = {'imageUrl': downloadUrl};
      await _sharedPreferences.storeMapValuesInSecureStorage(image);

      DocumentReference userRef = FirebaseFirestore.instance
          .doc('users/$uid');
      _firebaseService.uploadMapDataToFirestore(image, userRef);

      imageUrl = downloadUrl;
    } catch (e) {
      print('Error uploading file and storing URL: $e');
    } finally {
      _loadingDialog.dismiss();
    }
  }

  Future<void> getUserDetails() async {
    _name = await _sharedPreferences.getSecurePrefsValue('firstName');
    _regNo = await _sharedPreferences.getSecurePrefsValue('Registration Number');
    _imageUrl = await _sharedPreferences.getSecurePrefsValue('imageUrl');
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _loadingDialog.dismiss();
  }
}
