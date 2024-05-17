// File path: lib/pages/personal_details.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';

class PersonalDetails extends StatefulWidget {
  @override
  _PersonalDetailsState createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  DateTime? selectedDate;
  String selectedGender = 'Male';
  String name = '', regNo = '', email = '';

  SharedPreferences sharedPreferences = SharedPreferences();
  FireStoreService fireStoreService = new FireStoreService();
  LoadingDialog loadingDialog = new LoadingDialog();
  Utils utils = Utils();

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> getUserDetails() async {
    loadingDialog.showDefaultLoading('Getting Details...');
    name = (await sharedPreferences.getSecurePrefsValue('Name'))!;
    regNo = (await sharedPreferences.getSecurePrefsValue('Registration Number'))!;
    email = (await utils.getCurrentUserEmail())!;

    DocumentReference documentReference = FirebaseFirestore.instance.doc('UserDetails/${utils.getCurrentUserUID()}');
    Map<String, dynamic>? userData = await fireStoreService.getDocumentDetails(documentReference);

    if(userData!.containsKey('Gender')){
      selectedGender = userData['Gender'];
      print('Gender: $selectedGender');
    }
    if (userData.containsKey('DOB')) {
      Timestamp timestamp = userData['DOB'];
      selectedDate = timestamp.toDate();
      print('DOB: $selectedDate');
    }

    loadingDialog.dismiss();

    setState(() {});
  }

  Future<void> _updateDetails() async {
    loadingDialog.showDefaultLoading('Updating Data');
    Map<String,dynamic> userData = {'Gender':selectedGender,'DOB':selectedDate};
    DocumentReference documentReference = FirebaseFirestore.instance.doc('/UserDetails/${utils.getCurrentUserUID()}');
    fireStoreService.uploadMapDataToFirestore(userData, documentReference);
    loadingDialog.dismiss();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Name'),
                subtitle: Text(name.isEmpty ? 'Loading...' : name),
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: Icon(Icons.assignment_ind),
                title: Text('Registration Number'),
                subtitle: Text(regNo.isEmpty ? 'Loading...' : regNo),
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: Icon(Icons.email),
                title: Text('Email'),
                subtitle: Text(email.isEmpty ? 'Loading...' : email),
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: Icon(Icons.wc),
                title: Text('Gender'),
                trailing: DropdownButton<String>(
                  value: selectedGender,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedGender = newValue;
                      });
                    }
                  },
                  items: <String>['Male', 'Female']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Date of Birth'),
                trailing: ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Select Date',
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _updateDetails();
              },
              child: Text('Update'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
