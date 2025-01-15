import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import '../apis/googleDrive.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class MaterialsProvider with ChangeNotifier {
  final FireStoreService fireStoreService = FireStoreService();
  final LoadingDialog loadingDialog = LoadingDialog();
  final SharedPreferences sharedPreferences = SharedPreferences();
  final Utils utils = Utils();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  List<String> yearsList = ['1', '2', '3', '4'];
  List<String> branchList = ['CSE', 'ECE'];

  List<Map<String,String>> subjectsWithID = [];
  List<dynamic> _subjects = [];
  List<String> selectedSubjects = [];

  String? yearSelectedOption = '1';
  String? branchSelectedOption = 'CSE';
  String selectedSubject = '';
  String? streamSelectedOption;
  String? _announcementText;

  GoogleDriveService driveService = GoogleDriveService();


  MaterialsProvider() {
    initialize();
    fetchAnnouncementText();
  }

  Future<void> initialize() async {
    await getSharedPrefsValues();
    getSubjects();
  }

  Future<void> getSharedPrefsValues() async {
    yearSelectedOption =
        await sharedPreferences.getSecurePrefsValue('yearSelectedOption') ??
            yearsList.first;
    branchSelectedOption =
        await sharedPreferences.getSecurePrefsValue('branchSelectedOption') ??
            branchList.first;
    selectedSubjects =
        await sharedPreferences.getListFromSecureStorage('selectedSubjects');
    notifyListeners();
  }

  Future<void> fetchAnnouncementText() async {
    final DatabaseReference announcementRef =
        _database.ref('Materials/Announcement');
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


  Future<void> getSubjects() async {
    loadingDialog.showDefaultLoading('Getting subjects');
    subjects.clear();
    await driveService.authenticate();

    List<drive.File> folders = await driveService.listFoldersInFolder("1It2hLS1rcRLk46eLPz95m9mTXYY22WS2");

    for (var folder in folders) {
      if(folder.name == branchSelectedOption){
        List<drive.File> folders = await driveService.listFoldersInFolder(folder.id!);
        for(var folder in folders){
          if(folder.name == "YEAR $yearSelectedOption"){
            List<drive.File> allSubjects = await driveService.listFoldersInFolder(folder.id!);
            for(var subject in allSubjects){
              subjectsWithID.add({subject.name!: subject.id!});
            }
            notifyListeners();
            print('Subjects: $subjects');
          }else{
            print('Selected year not present $yearSelectedOption');
          }
        }
      }else{
        print('Selected Branch not present $branchSelectedOption');
      }
    }
    for (var subject in subjectsWithID) {
      subjects.add(subject.keys.first);  // Get the first (and only) key in the map
    }
    loadingDialog.dismiss();
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
    sharedPreferences.storeListInSecureStorage(
        selectedSubjects, 'selectedSubjects');
    loadingDialog.dismiss();
    super.dispose();
  }

  // Getters for UI
  String? get announcementText => _announcementText;
  List<dynamic> get  subjects => _subjects;
  String? get currentYearSelectedOption => yearSelectedOption;
  String? get currentBranchSelectedOption => branchSelectedOption;
  String? get currentStreamSelectedOption => streamSelectedOption;

  void currentYearSelection(String? value) {
    yearSelectedOption = value;
    notifyListeners();
  }

  void newStreamSelection(String? value) {
    streamSelectedOption = value;
    notifyListeners();
  }

  set setSelectedSubject(String value) {
    selectedSubject = value;
    notifyListeners(); // Notify listeners when the value is updated
  }
}
