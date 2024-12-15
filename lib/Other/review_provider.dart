import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Firebase/firestore.dart';
import '../Firebase/realtimedatabase.dart';
import '../services/sendnotification.dart';
import '../utils/LoadingDialog.dart';
import '../utils/utils.dart';

class ReviewProvider with ChangeNotifier {
  final Utils _utils = Utils();
  final RealTimeDatabase _realTimeDatabase = RealTimeDatabase();
  final FireStoreService _fireStoreService = FireStoreService();
  final LoadingDialog _loadingDialog = LoadingDialog();
  final NotificationService _notificationService = NotificationService();

  final TextEditingController _controller = TextEditingController();

  TextEditingController get controller => _controller;

  @override
  void dispose() {
    _controller.dispose();
    _loadingDialog.dismiss();
    super.dispose();
  }

  Future<void> submitReview(BuildContext context) async {
    if (_controller.text.isEmpty) {
      _utils.showToastMessage('Enter the text in the box');
      return;
    }

    _loadingDialog.showDefaultLoading('Submitting Review');

    String reviewText = _controller.text;

    try {
      int? id = await _realTimeDatabase.incrementValue('Reviews');

      Map<String, dynamic> reviewMap = {'${id.toString()}(${await _utils.getCurrentUserEmail()})': reviewText};

      DocumentReference reviewRef =
          FirebaseFirestore.instance.doc('/Reviews/${_utils.getTodayDate().replaceAll('/', '-')}/$id');

      await _fireStoreService.uploadMapDataToFirestore(reviewMap, reviewRef);

      DocumentReference reviewAdminRef = FirebaseFirestore.instance.doc('AdminDetails/Reviews');
      List<String> tokens = await _utils.getSpecificTokens(reviewAdminRef);
      _notificationService.sendNotification(tokens, 'Review', reviewText, {});

      _utils.showToastMessage('Review submitted');
      Navigator.pop(context);
    } catch (e) {
      _utils.showToastMessage('Failed to submit review');
      print('Error: $e');
    } finally {
      _loadingDialog.dismiss();
      notifyListeners();
    }
  }
}
