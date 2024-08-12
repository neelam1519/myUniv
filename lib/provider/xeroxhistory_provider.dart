import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../utils/utils.dart';

class XeroxHistoryProvider extends ChangeNotifier {
  final Utils _utils = Utils();
  final List<Map<String, dynamic>> _historyData = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get historyData => List.unmodifiable(_historyData);

  bool get isLoading => _isLoading;

  Future<void> fetchHistoryData() async {
    _isLoading = true;
    notifyListeners();

    EasyLoading.show(status: "Getting history...");
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('UserDetails/${_utils.getCurrentUserUID()}/XeroxHistory/').get();

      _historyData.clear();
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        _historyData.add(doc.data() as Map<String, dynamic>);
      }

      _historyData.sort((a, b) => a['ID'].compareTo(b['ID']));
      _historyData.sort((a, b) => b['ID'].compareTo(a['ID']));

      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.dismiss();
      print('Error fetching history data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
