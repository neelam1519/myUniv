import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Firebase/firestore.dart';
import '../services/sendnotification.dart';
import '../utils/LoadingDialog.dart';
import '../utils/utils.dart';

class QAndAProvider with ChangeNotifier {
  final Utils _utils = Utils();
  final FireStoreService _fireStoreService = FireStoreService();
  final NotificationService _notificationService = NotificationService();
  final LoadingDialog _loadingDialog = LoadingDialog();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();

  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  TextEditingController get searchController => _searchController;
  TextEditingController get questionController => _questionController;

  @override
  void dispose() {
    _searchController.dispose();
    _questionController.dispose();
    _loadingDialog.dismiss();
    super.dispose();
  }

  Future<void> addQuestion(BuildContext context) async {
    if (_questionController.text.isEmpty) {
      _utils.showToastMessage('Ask your question');
      return;
    }

    _loadingDialog.showDefaultLoading('Submitting your question');

    DocumentReference questionRef = _firestore.doc('Q&A/Questions');
    DocumentReference questionAdminRef = _firestore.doc('AdminDetails/Questions');
    List<String> tokens = await _utils.getSpecificTokens(questionAdminRef);
    _notificationService.sendNotification(tokens, 'Question', _questionController.text, {});

    Map<String, dynamic> question = {
      '${await _utils.getCurrentUserEmail()}/${DateTime.now().millisecondsSinceEpoch}': _questionController.text
    };

    await _fireStoreService.uploadMapDataToFirestore(question, questionRef);

    _questionController.clear();
    _utils.showToastMessage('Question is submitted you will get an update on your mail');
    _loadingDialog.dismiss();

    Navigator.pop(context); // Pop two times to go back to previous screens
    Navigator.pop(context);
  }

  set searchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  set isSearching(bool value) {
    _isSearching = value;
    notifyListeners();
  }
}
