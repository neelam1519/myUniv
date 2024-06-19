import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';

class AcademicDetails extends StatefulWidget {
  @override
  _AcademicDetailsState createState() => _AcademicDetailsState();
}

class _AcademicDetailsState extends State<AcademicDetails> {
  FireStoreService fireStoreService = FireStoreService();
  Utils utils = Utils();
  LoadingDialog loadingDialog = LoadingDialog();
  SharedPreferences sharedPreferences = SharedPreferences();

  // State variables for the dropdown values
  String? selectedYear;
  String? selectedBranch;
  String? selectedStream;
  String? selectedSection;

  // Lists of options for each dropdown
  List<String> years = ['1', '2', '3', '4'];
  List<String> branches = [];
  List<String> streams = [];
  List<String> sections = [];

  @override
  void initState() {
    super.initState();
    loadingDialog.showDefaultLoading('Getting Details...');
    getData();
  }

  Future<void> getData() async {
    DocumentReference documentReference = FirebaseFirestore.instance.doc('UserDetails/${utils.getCurrentUserUID()}');
    selectedYear = await sharedPreferences.getDataFromReference(documentReference, 'Year') ?? years[0];
    selectedBranch = await sharedPreferences.getDataFromReference(documentReference, 'Branch');
    selectedStream = await sharedPreferences.getDataFromReference(documentReference, 'Stream');
    selectedSection = await sharedPreferences.getDataFromReference(documentReference, 'Section');

    print('Details: $selectedYear  $selectedBranch $selectedStream  $selectedSection');
    await updateBranch();

    setState(() {});
    loadingDialog.dismiss();
  }
  Future<void> updateBranch() async {
    loadingDialog.showDefaultLoading('Getting Data...');
    if (selectedYear != null) {
      CollectionReference collectionReference = FirebaseFirestore.instance.doc('Years/$selectedYear').collection('Branches');

      branches = await fireStoreService.getDocumentNames(collectionReference);

      if (selectedBranch == null || !branches.contains(selectedBranch)) {
        selectedBranch = branches.isNotEmpty ? branches[0] : null;
      }

      await updateStream();

      print('Updated Branch: $branches');
      setState(() {});
    }
  }

  Future<void> updateStream() async {

    if (selectedYear != null && selectedBranch != null) {
      CollectionReference collectionReference = FirebaseFirestore.instance.doc('Years/$selectedYear/Branches/$selectedBranch').collection('Streams');
      streams = await fireStoreService.getDocumentNames(collectionReference);

      if (selectedStream == null || !streams.contains(selectedStream)) {
        selectedStream = streams.isNotEmpty ? streams[0] : null;
      }

      await updateSection();
      print('Updated streams: $streams');
      setState(() {});
    }
  }

  Future<void> updateSection() async {
    if (selectedYear != null && selectedBranch != null && selectedStream != null) {
      CollectionReference collectionReference = FirebaseFirestore.instance.doc('Years/$selectedYear/Branches/$selectedBranch/Streams/$selectedStream').collection('Sections');
      sections = await fireStoreService.getDocumentNames(collectionReference);

      if (selectedSection == null || !sections.contains(selectedSection)) {
        selectedSection = sections.isNotEmpty ? sections[0] : null;
      }

      print('Updated sections: $sections');
      setState(() {});
    }
    loadingDialog.dismiss();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Academic Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),  // Padding from the AppBar
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Year',
                      hintText: 'Select Year',
                    ),
                    value: selectedYear,
                    items: years.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        selectedYear = value;
                        selectedBranch = null;
                        selectedStream = null;
                        selectedSection = null;
                      });
                      await updateBranch();
                    },
                  ),
                  SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Branch',
                      hintText: 'Select Branch',
                    ),
                    value: selectedBranch,
                    items: branches.map((branch) {
                      return DropdownMenuItem(
                        value: branch,
                        child: Text(branch),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        selectedBranch = value;
                        selectedStream = null;
                        selectedSection = null;
                      });
                      await updateStream();
                    },
                  ),
                  SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Stream',
                      hintText: 'Select Stream',
                    ),
                    value: selectedStream,
                    items: streams.map((stream) {
                      return DropdownMenuItem(
                        value: stream,
                        child: Text(stream),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        selectedStream = value;
                        selectedSection = null;
                      });
                      await updateSection();
                    },
                  ),
                  SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Section',
                      hintText: 'Select Section',
                    ),
                    value: selectedSection,
                    items: sections.map((section) {
                      return DropdownMenuItem(
                        value: section,
                        child: Text(section),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSection = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle the update details action
                  print('Updated details: Year: $selectedYear, Branch: $selectedBranch, Stream: $selectedStream, Section: $selectedSection');
                  updateDetails(selectedYear, selectedBranch, selectedStream, selectedSection);
                },
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [Text('Update Details')],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateDetails(String? year, String? branch, String? stream, String? section) async {
    loadingDialog.showDefaultLoading('Updating Details...');
    Map<String, String> data = {
      'Year': year!,
      'Branch': branch!,
      'Stream': stream!,
      'Section': section!
    };
    DocumentReference documentReference = FirebaseFirestore.instance.doc('UserDetails/${utils.getCurrentUserUID()}');
    await fireStoreService.uploadMapDataToFirestore(data, documentReference);
    await sharedPreferences.storeMapValuesInSecureStorage(data);
    utils.showToastMessage('Academic Details updated', context);
    loadingDialog.dismiss();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    loadingDialog.dismiss();
  }
}
