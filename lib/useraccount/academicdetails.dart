import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';

class AcademicDetails extends StatefulWidget {
  @override
  _AcademicDetailsState createState() => _AcademicDetailsState();
}

class _AcademicDetailsState extends State<AcademicDetails> {
  final _formKey = GlobalKey<FormState>();

  FireStoreService fireStoreService = FireStoreService();
  LoadingDialog loadingDialog = LoadingDialog();
  Utils utils = Utils();

  String? _selectedYear;
  String? _selectedBranch;
  String? _selectedSpecialization;
  String? _selectedSection;

  List<String> _years = [];
  List<String> _branches = [];
  List<String> _specializations = [];
  List<String> _sections = [];

  @override
  void initState() {
    super.initState();
    loadingDialog.showDefaultLoading('Getting Details...');
    _fetchUserDetails();
    _fetchYears();
  }

  Future<void> _fetchUserDetails() async {
    try {
      String userUID = await utils.getCurrentUserUID();
      DocumentReference userRef = FirebaseFirestore.instance.doc("UserDetails/$userUID");

      Map<String, dynamic>? userData = await fireStoreService.getDocumentDetails(userRef);

      if (userData != null) {
        setState(() {
          _selectedYear = userData['YEAR'] ?? _selectedYear;
          _selectedBranch = userData['BRANCH'] ?? _selectedBranch;
          _selectedSpecialization = userData['SPECIALIZATION'] ?? _selectedSpecialization;
          _selectedSection = userData['SECTION'] ?? _selectedSection;
        });

        if (_selectedYear != null) {
          _fetchBranches(_selectedYear!);
        }
        if (_selectedYear != null && _selectedBranch != null) {
          _fetchSpecializations(_selectedYear!, _selectedBranch!);
        }
        if (_selectedYear != null && _selectedBranch != null && _selectedSpecialization != null) {
          _fetchSections(_selectedYear!, _selectedBranch!, _selectedSpecialization!);
        }
      } else {
        // Handle case where user data is not found or null
        print('User details not found.');
      }
    } catch (e) {
      print(e);
    } finally {
      loadingDialog.dismiss();
    }
  }


  Future<void> _fetchYears() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('AcademicDetails').get();
      List<String> years = snapshot.docs.map((doc) => doc.id).toList();
      setState(() {
        _years = years;
        if (_years.isNotEmpty && _selectedYear == null) {
          _selectedYear = _years[0];
          _fetchBranches(_selectedYear!);
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchBranches(String year) async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('AcademicDetails').doc(year).collection('BRANCHES').get();
      List<String> branches = snapshot.docs.map((doc) => doc.id).toList();
      setState(() {
        _branches = branches;
        if (_branches.isNotEmpty && _selectedBranch == null) {
          _selectedBranch = _branches[0];
          _fetchSpecializations(_selectedYear!, _selectedBranch!);
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchSpecializations(String year, String branch) async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('AcademicDetails').doc(year).collection('BRANCHES').doc(branch).collection('SPECIALIZATIONS').get();
      List<String> specializations = snapshot.docs.map((doc) => doc.id).toList();
      setState(() {
        _specializations = specializations;
        if (_specializations.isNotEmpty && _selectedSpecialization == null) {
          _selectedSpecialization = _specializations[0];
          _fetchSections(_selectedYear!, _selectedBranch!, _selectedSpecialization!);
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchSections(String year, String branch, String specialization) async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('AcademicDetails').doc(year).collection('BRANCHES').doc(branch).collection('SPECIALIZATIONS').doc(specialization).collection('SECTIONS').get();
      List<String> sections = snapshot.docs.map((doc) => doc.id).toList();
      setState(() {
        _sections = sections;
        if (_sections.isNotEmpty && _selectedSection == null) {
          _selectedSection = _sections[0];
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _updateDetails() async {
    try {
      String userUID = await utils.getCurrentUserUID();
      loadingDialog.showDefaultLoading('Updating Details...');

      DocumentReference userRef = FirebaseFirestore.instance.doc('UserDetails/$userUID');

      Map<String, dynamic> data = {
        'YEAR': _selectedYear!,
        'BRANCH': _selectedBranch!,
        'SPECIALIZATION': _selectedSpecialization!,
        'SECTION': _selectedSection!,
      };

      await userRef.set(data, SetOptions(merge: true));

      Navigator.pop(context);
      loadingDialog.dismiss();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Details updated successfully')));
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update details')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Academic Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Year'),
                value: _selectedYear,
                items: _years.map((String year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedYear = newValue;
                    _selectedBranch = null;
                    _selectedSpecialization = null;
                    _selectedSection = null;
                    _branches = [];
                    _specializations = [];
                    _sections = [];
                    _fetchBranches(newValue!);
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a year';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Branch'),
                value: _selectedBranch,
                items: _branches.map((String branch) {
                  return DropdownMenuItem<String>(
                    value: branch,
                    child: Text(branch),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedBranch = newValue;
                    _selectedSpecialization = null;
                    _selectedSection = null;
                    _specializations = [];
                    _sections = [];
                    _fetchSpecializations(_selectedYear!, newValue!);
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a branch';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Specialization'),
                value: _selectedSpecialization,
                items: _specializations.map((String specialization) {
                  return DropdownMenuItem<String>(
                    value: specialization,
                    child: Text(specialization),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedSpecialization = newValue;
                    _selectedSection = null;
                    _sections = [];
                    _fetchSections(_selectedYear!, _selectedBranch!, newValue!);
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a specialization';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Section'),
                value: _selectedSection,
                items: _sections.map((String section) {
                  return DropdownMenuItem<String>(
                    value: section,
                    child: Text(section),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedSection = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a section';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    _updateDetails();
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
