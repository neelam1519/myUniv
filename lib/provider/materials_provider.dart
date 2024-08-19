import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';

class MaterialsProvider with ChangeNotifier {
  final FireStoreService fireStoreService = FireStoreService();
  final LoadingDialog loadingDialog = LoadingDialog();
  final SharedPreferences sharedPreferences = SharedPreferences();
  final Utils utils = Utils();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  List<String?> yearsList = ['1', '2', '3', '4'];
  List<String?> branchList = ['CSE', 'ECE'];
  List<String?> specializations = [];
  List<String?> cseSpecialization = [
    'CYBER SECURITY',
    'ARTIFICIAL INTELLIGENCE AND MACHINE LEARNING',
    'DATA SCIENCE',
    'INTERNET OF THINGS'
  ];
  List<String?> eceSpecialization = [
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
  String? _announcementText;

  MaterialsProvider() {
    initialize();
    fetchAnnouncementText();
  }

  Future<void> initialize() async {
    await getSharedPrefsValues();
    getSpecialization();
    getSubjects();
  }

  Future<void> getSharedPrefsValues() async {
    yearSelectedOption = await sharedPreferences.getSecurePrefsValue('yearSelectedOption') ?? yearsList.first;
    branchSelectedOption = await sharedPreferences.getSecurePrefsValue('branchSelectedOption') ?? branchList.first;
    if (specializations.isNotEmpty) {
      streamSelectedOption = await sharedPreferences.getSecurePrefsValue('streamSelectedOption') ?? specializations.first;
    }
    selectedSubjects = await sharedPreferences.getListFromSecureStorage('selectedSubjects');
    notifyListeners();
  }

  Future<void> fetchAnnouncementText() async {
    final DatabaseReference announcementRef = _database.ref('Materials/Announcement');
    announcementRef.onValue.listen((event) {
      final DataSnapshot snapshot = event.snapshot;
      if (snapshot.exists) {
        _announcementText = snapshot.value as String?;
      } else {
        _announcementText = null;
      }
      notifyListeners();
    });
  }

  void getSpecialization() {
    if (branchSelectedOption == 'CSE') {
      specializations = cseSpecialization;
    } else if (branchSelectedOption == 'ECE') {
      specializations = eceSpecialization;
    }

    if (specializations.isNotEmpty) {
      if (streamSelectedOption == null || !specializations.contains(streamSelectedOption)) {
        streamSelectedOption = specializations.first;
      }
    }
    notifyListeners();
  }

  Future<void> getSubjects() async {
    loadingDialog.showDefaultLoading('Getting subjects');
    subjects.clear();
    DocumentReference branchRef = FirebaseFirestore.instance.doc('subjects/$yearSelectedOption/$branchSelectedOption/COMMON');
    DocumentReference streamRef = FirebaseFirestore.instance.doc('subjects/$yearSelectedOption/$branchSelectedOption/$streamSelectedOption');

    Map<String, dynamic>? branchDetails = await fireStoreService.getDocumentDetails(branchRef);
    Map<String, dynamic>? streamDetails = await fireStoreService.getDocumentDetails(streamRef);

    List<dynamic> branchValues = branchDetails?.values.toList() ?? [];
    List<dynamic> streamValues = streamDetails?.values.toList() ?? [];

    subjects.addAll(branchValues);
    subjects.addAll(streamValues);
    sortSubjects();

    notifyListeners();
    loadingDialog.dismiss();
  }

  void sortSubjects() {
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
    notifyListeners();
  }

  Future<void> updateSharedPrefsValues() async {
    Map<String, String> values = {
      'streamSelectedOption': streamSelectedOption!,
      'branchSelectedOption': branchSelectedOption!,
      'yearSelectedOption': yearSelectedOption!,
    };
    sharedPreferences.storeMapValuesInSecureStorage(values);
  }

  @override
  void dispose() {
    sharedPreferences.storeListInSecureStorage(selectedSubjects, 'selectedSubjects');
    loadingDialog.dismiss();
    super.dispose();
  }

  // Getters for UI
  String? get announcementText => _announcementText;
  List<String?> get availableSpecializations => specializations;
  List<dynamic> get availableSubjects => subjects;
  String? get currentYearSelectedOption => yearSelectedOption;
  String? get currentBranchSelectedOption => branchSelectedOption;
  String? get currentStreamSelectedOption => streamSelectedOption;

  void currentYearSelection(String? value){
    yearSelectedOption = value;
    notifyListeners();
  }

  void newStreamSelection(String? value){
    streamSelectedOption = value;
    notifyListeners();
  }


}
