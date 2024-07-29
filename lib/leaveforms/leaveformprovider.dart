import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaveFormProvider with ChangeNotifier {
  Map<String, dynamic> _leaveData = {};
  DocumentReference? _documentReference;

  Map<String, dynamic> get leaveData => _leaveData;
  DocumentReference? get documentReference => _documentReference;

  void setLeaveData(Map<String, dynamic> data, DocumentReference reference) {
    _leaveData = data;
    _documentReference = reference;
    notifyListeners();
  }

  void updateApprovalStatus(bool isApproved) {
    _leaveData['finalApproval']['status'] = isApproved;
    notifyListeners();
  }
}
