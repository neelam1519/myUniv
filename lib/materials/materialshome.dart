import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/materials/units.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:flutter/material.dart';

class MaterialsHome extends StatefulWidget {
  @override
  _MaterialsHomeState createState() => _MaterialsHomeState();
}

class _MaterialsHomeState extends State<MaterialsHome> {
  FireStoreService fireStoreService = new FireStoreService();
  LoadingDialog loadingDialog = new LoadingDialog();
  SharedPreferences sharedPreferences = new SharedPreferences();

  List<String?> yearsList = ['1', '2', '3', '4'];
  List<String?> branchList = ['CSE', 'ECE'];

  List<String?> specializations = [];

  List<String?> cse_specialization = [
    'CYBER SECURITY',
    'ARTIFICIAL INTELLIGENCE AND MACHINE LEARNING',
    'DATA SCIENCE',
    'INTERNET OF THINGS'
  ];
  List<String?> ece_specialization = [
    'ARTIFICIAL INTELLIGENCE FOR CYBER SECURITY',
    'EMBEDDED AND INTERNET OF THINGS',
    'MICROCHIP PHYSICAL DESIGN',
    'INTEGRATED CIRCUITS DESIGN AND VERIFICATION'
  ];

  List<dynamic> subjects = [];
  List<String> selectedSubjects = [];

  String? yearSelectedOption = '1';
  String? branchSelectedOption = 'CSE';
  String? streamSelectedOption;

  @override
  void initState() {
    super.initState();
    intialize();
  }

  Future<void> intialize() async {
    await getSharedPrefsValues().then((value) {
      getSpecialization();
      getSubjects();
    });
  }

  Future<void> getSharedPrefsValues() async {
    yearSelectedOption =
        await sharedPreferences.getSecurePrefsValue('yearSelectedOption') ?? yearsList.first;
    branchSelectedOption =
        await sharedPreferences.getSecurePrefsValue('branchSelectedOption') ?? branchList.first;
    if(specializations.isNotEmpty) {
      streamSelectedOption =
          await sharedPreferences.getSecurePrefsValue('streamSelectedOption') ??
              specializations.first;
    }
    selectedSubjects = await sharedPreferences.getListFromSecureStorage('selectedSubjects');

    print('Selected Subjects: $selectedSubjects');
  }

  void getSpecialization() {
    if (branchSelectedOption == 'CSE') {
      specializations = cse_specialization;
    } else if (branchSelectedOption == 'ECE') {
      specializations = ece_specialization;
    }

    if (specializations.isNotEmpty) {
      if (streamSelectedOption == null || !specializations.contains(streamSelectedOption)) {
        streamSelectedOption = specializations.first;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print('Build is running  :$specializations');
    return Scaffold(
      appBar: AppBar(
        title: Text('Subjects'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return SingleChildScrollView(
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 20.0),
                              Text(
                                'Year',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              DropdownButton<String>(
                                value: yearSelectedOption,
                                onChanged: (String? newValue) async {
                                  setState(() {
                                    yearSelectedOption = newValue!;
                                  });
                                  getSpecialization();
                                },
                                isDense: true,
                                items: yearsList
                                    .map<DropdownMenuItem<String>>((String? value) {
                                  return DropdownMenuItem<String>(
                                    value: value!,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 20.0),
                              Text(
                                'Branch',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              DropdownButton<String>(
                                value: branchSelectedOption,
                                onChanged: (String? newValue) async {
                                  setState(() {
                                    branchSelectedOption = newValue!;
                                  });
                                  getSpecialization();
                                },
                                isDense: true,
                                items: branchList
                                    .map<DropdownMenuItem<String>>((String? value) {
                                  return DropdownMenuItem<String>(
                                    value: value!,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 20.0),
                              Text(
                                'Stream',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              DropdownButton<String>(
                                value: streamSelectedOption,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    streamSelectedOption = newValue!;
                                  });
                                },
                                isDense: true,
                                items: specializations
                                    .map<DropdownMenuItem<String>>((String? value) {
                                  return DropdownMenuItem<String>(
                                    value: value!,
                                    child: Container(
                                      child: Text(value),
                                    ),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 20.0),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  getSubjects();
                                  updateSharedPrefsValues();
                                },
                                child: Text('submit'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ListView.builder(
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: ListTile(
                title: Text(subjects[index]),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Units(path: 'materials/$yearSelectedOption/${subjects[index]}')));
                  setState(() {
                    if (selectedSubjects.contains(subjects[index])) {
                      selectedSubjects.remove(subjects[index]);
                      selectedSubjects.insert(0, subjects[index]);
                    } else {
                      selectedSubjects.insert(0, subjects[index]);
                      print('Added to the first');
                    }
                    // Sort the subjects list based on the index of each subject in the selectedSubjects list
                    subjects.sort((a, b) {
                      int indexA = selectedSubjects.indexOf(a);
                      int indexB = selectedSubjects.indexOf(b);
                      if (indexA == -1 && indexB == -1) {
                        return 0;
                      } else if (indexA == -1) {
                        return 1;
                      } else if (indexB == -1) {
                        return -1;
                      }
                      return indexA.compareTo(indexB);
                    });
                    print('onTap Selected Subjects: $selectedSubjects');
                    print('Subjects: $subjects');
                  });
                },
              ),
            );
          },
        ),
      ),

    );
  }

  Future<void> getSubjects() async {
    loadingDialog.showDefaultLoading('Getting subjects');

    subjects.clear();
    DocumentReference branchRef =
    FirebaseFirestore.instance.doc('subjects/$yearSelectedOption/$branchSelectedOption/COMMON');
    DocumentReference streamRef = FirebaseFirestore.instance
        .doc('subjects/$yearSelectedOption/$branchSelectedOption/$streamSelectedOption');

    Map<String, dynamic>? branchDetails = await fireStoreService.getDocumentDetails(branchRef);
    Map<String, dynamic>? streamDetails = await fireStoreService.getDocumentDetails(streamRef);

    List<dynamic> branchValues = [];
    List<dynamic> streamValues = [];

    if (branchDetails != null) {
      branchValues = branchDetails.values.toList();
    }

    if (streamDetails != null) {
      streamValues = streamDetails.values.toList();
    }

    print('Document Ref: $branchRef  $streamRef');
    print('Subjects values ${branchValues}   $streamValues');

    subjects.addAll(branchValues);
    subjects.addAll(streamValues);

    // Sort the subjects list based on the index of each subject in the selectedSubjects list
    subjects.sort((a, b) {
      int indexA = selectedSubjects.indexOf(a);
      int indexB = selectedSubjects.indexOf(b);
      if (indexA == -1 && indexB == -1) {
        return 0;
      } else if (indexA == -1) {
        return 1;
      } else if (indexB == -1) {
        return -1;
      }
      return indexA.compareTo(indexB);
    });
    setState(() {

    });
    loadingDialog.dismiss();
  }

  Future<void> updateSharedPrefsValues() async {
    Map<String, String> values = {
      'streamSelectedOption': streamSelectedOption!,
      'branchSelectedOption': branchSelectedOption!,
      'yearSelectedOption': yearSelectedOption!
    };
    sharedPreferences.storeMapValuesInSecureStorage(values);
  }

  @override
  void dispose() {
    super.dispose();
    print('Storing Selected Subjects: $selectedSubjects');
    sharedPreferences.storeListInSecureStorage(selectedSubjects, 'selectedSubjects');
  }
}
