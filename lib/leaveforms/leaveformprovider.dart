import 'package:flutter/material.dart';

class LeaveFormProvider with ChangeNotifier {
  List<Map<String, dynamic>> _leaveData = [];
  String? id;

  String? _selectedRole;
  String? _selectedStatus;
  String? _selectedStream;

  List<String> roles = [];
  List<String> stream = [];
  List<String> sectionYear = [];

  List<Map<String, dynamic>> get leaveData => _leaveData;
  String? get leaveID => id;
  String? get selectedRole => _selectedRole;
  String? get selectedStatus => _selectedStatus;
  String? get selectedStream => _selectedStream;

  void setLeaveID(String leaveID) {
    id = leaveID;
    notifyListeners();
  }

  void updateRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  void updateStream(String stream) {
    _selectedStream = stream;
    notifyListeners();
  }

  void updateStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void updateDropDown(List<String> role, List<String> streams, List<String> sectionyear) {
    roles = role;
    stream = streams;
    sectionYear = sectionyear;
    _selectedRole = roles.isNotEmpty ? roles[0] : null;
    _selectedStream = stream.isNotEmpty ? stream[0] : null;
    _selectedStatus = sectionYear.isNotEmpty ? sectionYear[0] : null;
    notifyListeners();
  }

  void addLeaveData(List<Map<String, dynamic>> data) {
    _leaveData = data;
    notifyListeners();
  }

  void addOneLeaveData(Map<String, dynamic> newLeaveData) {
    _leaveData.insert(0, newLeaveData);
    notifyListeners();
  }

  void clearLeaveData() {
    _leaveData = [];
    notifyListeners();
  }

  void updateLeaveData(int index, Map<String, dynamic> updatedData) {
    _leaveData[index] = updatedData;
    notifyListeners();
  }

  void removeLeaveData(int index) {
    _leaveData.removeAt(index);
    notifyListeners();
  }
}
