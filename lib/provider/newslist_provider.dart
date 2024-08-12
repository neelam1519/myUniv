import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:findany_flutter/utils/utils.dart';

class NewsListProvider with ChangeNotifier {
  final Utils utils = Utils();
  String searchQuery = '';
  bool isAdmin = false;

  Stream<List<DocumentSnapshot>> get newsStream {
    return FirebaseFirestore.instance
        .collection('news')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> checkAdminStatus() async {
    String? email = await utils.getCurrentUserEmail();
    String id = utils.removeEmailDomain(email!);
    DocumentReference userRef = FirebaseFirestore.instance.doc('AdminDetails/UniversityNews');
    List<String> admins = await utils.getAdmins(userRef);
    isAdmin = admins.contains(id);
    notifyListeners();
  }

  List<DocumentSnapshot> filterNews(List<DocumentSnapshot> docs) {
    if (searchQuery.isEmpty) {
      return docs;
    }
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = data['title'] as String;
      final summary = data['summary'] as String;
      return title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          summary.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  void updateSearchQuery(String query) {
    searchQuery = query.toLowerCase();
    notifyListeners();
  }
}
