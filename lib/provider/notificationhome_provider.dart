import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../utils/utils.dart';

class NotificationHomeProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Utils utils = Utils();
  bool _isAdmin = false;

  bool get isAdmin => _isAdmin;

  Future<void> checkAdminStatus() async {
    final email = await utils.getCurrentUserEmail();
    if (email != null) {
      final id = utils.removeEmailDomain(email);
      final userRef = _firestore.doc('AdminDetails/Notifications');
      final admins = await utils.getAdmins(userRef);
      if (_isAdmin != admins.contains(id)) {
        _isAdmin = admins.contains(id);
        notifyListeners();
      }
    }
  }
}
