import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/leaveforms/leaveformdetails.dart';
import 'package:findany_flutter/leaveforms/leaveformprovider.dart';
import 'package:findany_flutter/leaveforms/leavefromdetailsshow.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'leaveformstats.dart';

class LecturerLeaveHome extends StatefulWidget {
  @override
  _LecturerLeaveHomeState createState() => _LecturerLeaveHomeState();
}

class _LecturerLeaveHomeState extends State<LecturerLeaveHome> {
  Utils utils = Utils();
  FireStoreService fireStoreService = FireStoreService();
  LoadingDialog loadingDialog = LoadingDialog();
  int _selectedIndex = 0;

  static const List<String> _collectionNames = [
    'PENDING',
    'ACCEPTED',
    'REJECTED',
    'STATS'
  ];

  String? selectedRole;
  String? selectedStream;
  String? selectedStatus;
  List<String> roles = [];
  List<String> streams = [];
  List<String> sectionYears = [];

  String streamText="STREAM";
  String sectionYearText="SECTION/YEAR";

  Map<String, dynamic>? rolesData = {};

  List<Map<String, dynamic>> leaveData = [];

  @override
  void initState() {
    super.initState();
    loadingDialog.showDefaultLoading("Getting LeaveForms");
    getRoleData();
  }

  Future<void> getRoleData() async {
    String? email = await utils.getCurrentUserEmail();
    DocumentReference rolesRef = FirebaseFirestore.instance.doc("/AcademicDetails/STAFFDETAILS/ROLES/$email");
    rolesData = await fireStoreService.getDocumentDetails(rolesRef);
    roles = List<String>.from(rolesData!['ROLES']);

    if (selectedRole == null && roles.isNotEmpty) {
      selectedRole = roles[0];
      updateDropdown(selectedRole!);
    } else {
      updateDropdown(selectedRole!);
    }
    print('Roles Data: $rolesData');
    fetchAllLeaveForms('PENDING', selectedRole!, selectedStatus!, rolesData!["BRANCH"], selectedStream!);
  }

  Future<void> fetchAllLeaveForms(String status, String role, String sectionYear, String branch, String stream) async {
    loadingDialog.showDefaultLoading("Getting LeaveForms");
    final leaveFormProvider = Provider.of<LeaveFormProvider>(context, listen: false);
    CollectionReference collectionReference = FirebaseFirestore.instance.collection("AcademicDetails");

    DocumentReference documentReference = FirebaseFirestore.instance.doc("AcademicDetails/ErrorLeaveForms");

    if (role == 'FACULTY ADVISOR') {
      documentReference = FirebaseFirestore.instance.doc('/AcademicDetails/${rolesData!["FACULTY ADVISOR YEAR"]}/BRANCHES/$branch/SPECIALIZATIONS/$stream/SECTIONS/$sectionYear/$role LEAVEFORMS/$status');
    } else if(role=="YEAR COORDINATOR"){
      documentReference = FirebaseFirestore.instance.doc('/AcademicDetails/$sectionYear/BRANCHES/$branch/SPECIALIZATIONS/$stream/LEAVEFORMS/$status');
    }else if(role == "HOD"){
      documentReference = FirebaseFirestore.instance.doc('/AcademicDetails/$sectionYear/BRANCHES/$branch/LEAVEFORMS/$status');
    }else if(role == "HOSTEL WARDEN"){
      documentReference = FirebaseFirestore.instance.doc("HostelDetails/BHATGHAT SINGH HOSTEL/LEAVEFORMS/$status");
    }

    print("Document Reference: ${documentReference.path}");

    List<Map<String, dynamic>> allLeaveData = [];

    Map<String, dynamic>? leaveRef = await fireStoreService.getDocumentDetails(documentReference);

    if (leaveRef != null) {
      for (var entry in leaveRef.entries) {
        DocumentReference ref = entry.value as DocumentReference;
        DocumentSnapshot doc = await ref.get();
        allLeaveData.add({doc.id: doc.data()});
      }
    }

    allLeaveData.sort((a, b) => int.parse(a.keys.first).compareTo(int.parse(b.keys.first)));

    setState(() {
      leaveData.clear();
      leaveData.addAll(allLeaveData);
      leaveFormProvider.clearLeaveData();
      leaveFormProvider.addLeaveData(leaveData);
    });

    loadingDialog.dismiss();
  }

  void updateDropdown(String role) {
    final leaveFormProvider = Provider.of<LeaveFormProvider>(context, listen: false);

    if (role == "FACULTY ADVISOR") {
      streams = List<String>.from(rolesData!["FACULTY ADVISOR STREAM"]);
      sectionYears = List<String>.from(rolesData!["FACULTY ADVISOR SECTION"]);
      sectionYearText="SECTION";
    } else if (role == "YEAR COORDINATOR" || role =="H0D") {
      streams = List<String>.from(rolesData!["YEAR COORDINATOR STREAM"]);
      sectionYears = List<String>.from(rolesData!["YEAR COORDINATOR YEAR"]);
      sectionYearText="YEAR";
    }else if(role == "HOSTEL WARDEN"){
      streamText = "HOSTEL NAME";
      streams =['BHAGHATH SINGH HOSTEL'];
    }

    leaveFormProvider.updateRole(role);
    setState(() {
      selectedStream = streams.isNotEmpty ? streams[0] : null;
      selectedStatus = sectionYears.isNotEmpty ? sectionYears[0] : null;
    });
  }

  void _showFilterDialog() {
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
                      'Role',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    DropdownButton<String>(
                      value: selectedRole,
                      onChanged: (String? newValue) async {
                        setState(() {
                          selectedRole = newValue!;
                        });
                        updateDropdown(newValue!);
                      },
                      isDense: true,
                      items: roles.map<DropdownMenuItem<String>>((String? value) {
                        return DropdownMenuItem<String>(
                          value: value!,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    if (true) ...[
                      SizedBox(height: 20.0),
                      Text(
                        streamText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      DropdownButton<String>(
                        value: selectedStream,
                        onChanged: (String? newValue) async {
                          setState(() {
                            selectedStream = newValue!;
                          });
                        },
                        isDense: true,
                        items: streams.map<DropdownMenuItem<String>>((String? value) {
                          return DropdownMenuItem<String>(
                            value: value!,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                    if (selectedRole != "HOSTEL WARDEN") ...[
                      SizedBox(height: 20.0),
                      Text(
                        sectionYearText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      DropdownButton<String>(
                        value: selectedStatus,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedStatus = newValue!;
                          });
                        },
                        isDense: true,
                        items: sectionYears.map<DropdownMenuItem<String>>((String? value) {
                          return DropdownMenuItem<String>(
                            value: value!,
                            child: Container(
                              child: Text(value),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        fetchAllLeaveForms(
                            'PENDING',
                            selectedRole!,
                            selectedStatus!,
                            rolesData!["BRANCH"],
                            selectedStream!
                        );
                      },
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Future<void> acceptAllForms() async {
    loadingDialog.showDefaultLoading('Accept all Forms of $selectedStatus');

    String acceptName = "";
    if (selectedRole == "FACULTY ADVISOR") {
      acceptName = "facultyAdvisorApproval";
    } else if (selectedRole == "YEAR COORDINATOR") {
      acceptName = "yearCoordinatorApproval";
    } else if (selectedRole == "HOD") {
      acceptName = "hodApproval";
    }

    for (Map<String, dynamic> form in leaveData) {
      String key = form.keys.first;
      DocumentReference documentReference = FirebaseFirestore.instance.doc("LeaveForms/$key");

      await documentReference.update({
        '$acceptName.status': "ACCEPTED",
      }).then((_) {
        print('Form $key accepted.');
      }).catchError((error) {
        print('Failed to update form $key: $error');
      });
    }
    loadingDialog.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Forms'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          if (selectedRole == "YEAR COORDINATOR" || selectedRole == "HOD")
            IconButton(
              icon: Icon(Icons.check),
              onPressed: acceptAllForms,
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _collectionNames.map((status) {
          final leaveFormProvider = Provider.of<LeaveFormProvider>(context);
          final providerData = leaveFormProvider.leaveData;

          if (providerData.isEmpty) {
            return Center(child: Text('No $status leave forms found.'));
          } else {
            return ListView.builder(
              itemCount: providerData.length,
              itemBuilder: (context, index) {
                var dataMap = providerData[index];
                var docId = dataMap.keys.first;
                var data = dataMap[docId] as Map<String, dynamic>;

                return GestureDetector(
                  onTap: () {
                    print('Index: $index');
                    if (status == "PENDING") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeaveFormDetails(
                            index: index,
                            sectionYear: selectedStatus!,
                            branch: rolesData!["BRANCH"],
                            stream: selectedStream!,
                            faYear: rolesData!["FACULTY ADVISOR YEAR"],
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeaveFormDetailsShow(index: index),
                        ),
                      );
                    }
                  },
                  child: Card(
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student ID: ${data['studentId']}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'From: ${data['fromDate']}',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'To: ${data['toDate']}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Reason: ${data['reason']}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Final Approval: ${data['finalApproval']['status']}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        }).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_empty),
            label: 'Pending',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'Accepted',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.close),
            label: 'Rejected',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Stats',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue, // Set the color for the selected item
        unselectedItemColor: Colors.grey, // Set the color for the unselected items
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if(_collectionNames[_selectedIndex] == "STATS"){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Leaveformstats()
                ),
              );
              return;
            }
            fetchAllLeaveForms(_collectionNames[_selectedIndex], selectedRole!, selectedStatus!, rolesData!["BRANCH"], selectedStream!);
          });
        },
      ),
    );

  }
}
