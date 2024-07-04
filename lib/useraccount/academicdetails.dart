import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicDetails extends StatefulWidget {
  @override
  _AcademicDetailsState createState() => _AcademicDetailsState();
}

class _AcademicDetailsState extends State<AcademicDetails> {
  final _formKey = GlobalKey<FormState>();
  LoadingDialog loadingDialog = LoadingDialog();

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
    _fetchYears();
  }

  Future<void> _fetchYears() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('AcademicDetails').get();
      List<String> years = snapshot.docs.map((doc) => doc.id).toList();
      setState(() {
        _years = years;
        if (_years.isNotEmpty) {
          _selectedYear = _years[0];
          _fetchBranches(_selectedYear!);
        }else{
          loadingDialog.dismiss();
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
        if (_branches.isNotEmpty) {
          _selectedBranch = _branches[0];
          _fetchSpecializations(_selectedYear!, _selectedBranch!);
        }else{
          loadingDialog.dismiss();
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
        if (_specializations.isNotEmpty) {
          _selectedSpecialization = _specializations[0];
          _fetchSections(_selectedYear!, _selectedBranch!, _selectedSpecialization!);
        }else{
          loadingDialog.dismiss();
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
        if (_sections.isNotEmpty) {
          _selectedSection = _sections[0];
        }
        loadingDialog.dismiss();

      });
    } catch (e) {
      print(e);
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
                    print('Year: $_selectedYear, Branch: $_selectedBranch, Specialization: $_selectedSpecialization, Section: $_selectedSection');
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
  @override
  void dispose() {
    // TODO: implement dispos
    super.dispose();
    loadingDialog.dismiss();
  }
}
