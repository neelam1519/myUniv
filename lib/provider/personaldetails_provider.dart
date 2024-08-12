import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';

class PersonalDetailsProvider extends ChangeNotifier {
  DateTime? dob;
  String _selectedGender = 'Male';
  String _name = '', _regNo = '', _email = '', _username = '';

  String get selectedGender => _selectedGender;
  String get name => _name;
  String get regNo => _regNo;
  String get email => _email;
  String get username => _username;
  TextEditingController usernameController = TextEditingController();

  final SharedPreferences sharedPreferences = SharedPreferences();
  final FireStoreService fireStoreService = FireStoreService();
  final LoadingDialog loadingDialog = LoadingDialog();
  final Utils utils = Utils();

  Future<void> initialize() async {
    // Initialization logic, if needed
  }

  Future<void> getUserDetails() async {
    DocumentReference documentReference = FirebaseFirestore.instance.doc('UserDetails/${utils.getCurrentUserUID()}');

    DateTime currentTime = DateTime.now();
    loadingDialog.showDefaultLoading('Getting Details...');
    _name = await sharedPreferences.getDataFromReference(documentReference, 'Name') ?? '';
    _regNo = await sharedPreferences.getDataFromReference(documentReference, 'Registration Number') ?? '';
    _email = await sharedPreferences.getDataFromReference(documentReference, 'Email') ?? '';
    _selectedGender = await sharedPreferences.getDataFromReference(documentReference, 'Gender') ?? 'Male';
    _username = await sharedPreferences.getDataFromReference(documentReference, 'Username') ?? '';

    usernameController.text = _username;

    var dobData = await sharedPreferences.getDataFromReference(documentReference, 'DOB');
    if (dobData is String) {
      dob = DateTime.tryParse(dobData);
    } else if (dobData is Timestamp) {
      dob = dobData.toDate();
    }
    dob = dob ?? currentTime;
    loadingDialog.dismiss();

    notifyListeners();
  }

  Future<void> updateDetails() async {
    _username = usernameController.text;
    if (_username.isEmpty) {
      utils.showToastMessage('Enter your username');
      return;
    }
    loadingDialog.showDefaultLoading('Updating Data');
    Map<String, dynamic> userData = {
      'Gender': _selectedGender,
      'DOB': dob!.toIso8601String(),
      'Username': _username,
    };
    DocumentReference documentReference = FirebaseFirestore.instance.doc('/UserDetails/${utils.getCurrentUserUID()}');
    fireStoreService.uploadMapDataToFirestore(userData, documentReference);

    sharedPreferences.storeMapValuesInSecureStorage(userData);
    loadingDialog.dismiss();
    utils.showToastMessage('Details updated');
    notifyListeners();
  }

  void setGender(String gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  void setDateOfBirth(DateTime date) {
    dob = date;
    notifyListeners();
  }

  void setUsername(String username) {
    _username = username;
    notifyListeners();
  }
}
