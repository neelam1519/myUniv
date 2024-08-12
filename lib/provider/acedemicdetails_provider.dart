import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';

class AcademicDetailsProvider with ChangeNotifier {
  final FireStoreService fireStoreService = FireStoreService();
  final Utils utils = Utils();
  final LoadingDialog loadingDialog = LoadingDialog();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? selectedYear;
  String? selectedBranch;
  String? selectedSpecialization;
  String? selectedSection;

  List<String> years = [];
  List<String> branches = [];
  List<String> specializations = [];
  List<String> sections = [];

  Future<void> init() async {
    loadingDialog.showDefaultLoading('Getting Details...');
    await fetchUserDetails();
    await fetchYears();
  }

  Future<void> fetchUserDetails() async {
    try {
      String? userUID = await utils.getCurrentUserUID();
      DocumentReference userRef = FirebaseFirestore.instance.doc("UserDetails/$userUID");

      Map<String, dynamic>? userData = await fireStoreService.getDocumentDetails(userRef);

      if (userData != null) {
        selectedYear = userData['YEAR'];
        selectedBranch = userData['BRANCH'];
        selectedSpecialization = userData['SPECIALIZATION'];
        selectedSection = userData['SECTION'];

        if (selectedYear != null) {
          await fetchBranches(selectedYear!);
        }
        if (selectedYear != null && selectedBranch != null) {
          await fetchSpecializations(selectedYear!, selectedBranch!);
        }
        if (selectedYear != null && selectedBranch != null && selectedSpecialization != null) {
          await fetchSections(selectedYear!, selectedBranch!, selectedSpecialization!);
        }
        notifyListeners();
      } else {
        print('User details not found.');
      }
    } catch (e) {
      print(e);
    } finally {
      loadingDialog.dismiss();
    }
  }

  Future<void> fetchYears() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('AcademicDetails').get();
      years = snapshot.docs.map((doc) => doc.id).toList();
      if (years.isNotEmpty && selectedYear == null) {
        selectedYear = years[0];
        await fetchBranches(selectedYear!);
      }
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchBranches(String year) async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('AcademicDetails').doc(year).collection('BRANCHES').get();
      branches = snapshot.docs.map((doc) => doc.id).toList();
      if (branches.isNotEmpty && selectedBranch == null) {
        selectedBranch = branches[0];
        await fetchSpecializations(selectedYear!, selectedBranch!);
      }
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchSpecializations(String year, String branch) async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('AcademicDetails').doc(year).collection('BRANCHES').doc(branch).collection('SPECIALIZATIONS').get();
      specializations = snapshot.docs.map((doc) => doc.id).toList();
      if (specializations.isNotEmpty && selectedSpecialization == null) {
        selectedSpecialization = specializations[0];
        await fetchSections(selectedYear!, selectedBranch!, selectedSpecialization!);
      }
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchSections(String year, String branch, String specialization) async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('AcademicDetails').doc(year).collection('BRANCHES').doc(branch).collection('SPECIALIZATIONS').doc(specialization).collection('SECTIONS').get();
      sections = snapshot.docs.map((doc) => doc.id).toList();
      if (sections.isNotEmpty && selectedSection == null) {
        selectedSection = sections[0];
      }
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateDetails(BuildContext context) async {
    try {
      String? userUID = await utils.getCurrentUserUID();
      loadingDialog.showDefaultLoading('Updating Details...');

      DocumentReference userRef = FirebaseFirestore.instance.doc('UserDetails/$userUID');

      Map<String, dynamic> data = {
        'YEAR': selectedYear!,
        'BRANCH': selectedBranch!,
        'SPECIALIZATION': selectedSpecialization!,
        'SECTION': selectedSection!,
      };

      await userRef.set(data, SetOptions(merge: true));

      Navigator.pop(context);
      loadingDialog.dismiss();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details updated successfully')));
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update details')));
    }
  }
}
