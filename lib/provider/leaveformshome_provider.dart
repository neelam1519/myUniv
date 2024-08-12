// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// import '../Firebase/firestore.dart';
// import '../Firebase/realtimedatabase.dart';
// import '../leaveforms/leaveapplication.dart';
// import '../utils/utils.dart';
//
// class LeaveFormsHomeProvider with ChangeNotifier {
//   final TextEditingController _leaveDetailsController = TextEditingController();
//   final Utils _utils = Utils();
//   final RealTimeDatabase _realTimeDatabase = RealTimeDatabase();
//   final FireStoreService _fireStoreService = FireStoreService();
//   final User? _user = FirebaseAuth.instance.currentUser;
//
//   TextEditingController get leaveDetailsController => _leaveDetailsController;
//   Utils get utils => _utils;
//   RealTimeDatabase get realTimeDatabase => _realTimeDatabase;
//   FireStoreService get fireStoreService => _fireStoreService;
//   User? get user => _user;
//
//   Future<void> leaveFormApply(BuildContext context) async {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const LeaveApplicationForm()),
//     );
//   }
//
//   Future<Map<String, Map<String, dynamic>>> getLeaveDetails() async {
//     String? uid = await utils.getCurrentUserUID();
//     DocumentReference documentReference = FirebaseFirestore.instance.doc("/UserDetails/$uid/LeaveForms/LeaveApplications");
//     Map<String, dynamic>? data = await _fireStoreService.getDocumentDetails(documentReference);
//
//     Map<String, Map<String, dynamic>> allData = {};
//
//     if (data != null) {
//       for (var entry in data.entries) {
//         if (entry.value is DocumentReference) {
//           DocumentReference leaveFormRef = entry.value;
//           Map<String, dynamic>? leaveFormData = await _fireStoreService.getDocumentDetails(leaveFormRef);
//           if (leaveFormData != null) {
//             allData[entry.key] = leaveFormData;
//           }
//         }
//       }
//     }
//
//     Map<String, Map<String, dynamic>> reversedAllData = Map.fromEntries(allData.entries.toList());
//
//     print("Reversed All Data: $reversedAllData");
//
//     notifyListeners();
//
//     return reversedAllData;
//   }
//
//   @override
//   void dispose() {
//     _leaveDetailsController.dispose();
//     super.dispose();
//   }
// }
