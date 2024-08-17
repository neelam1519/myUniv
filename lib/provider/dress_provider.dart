import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

class DressProvider extends ChangeNotifier {

  final FireStoreService fireStoreService = FireStoreService();
  String? _announcementText;

  final List<String> _category = ["Men"];
  final Map<String, List<String>> _subCategory = {"Men":["Shorts"]};
  bool _isOwner = false;

  bool get isOwner => _isOwner;
  List<String> get categories => _category;
  Map<String, List<String>> get subCategories => _subCategory;
  String? get announcementText => _announcementText;

  StreamSubscription<DatabaseEvent>? _announcementSubscription;

  @override
  void dispose() {
    super.dispose();
    _announcementSubscription?.cancel();
  }

  Future<void> getCategories() async {
    CollectionReference collectionReference =
    FirebaseFirestore.instance.collection("SHOPS/DRESSSHOP/Category");
    List<String> documents =
    await fireStoreService.getDocumentNames(collectionReference);

    for (String str in documents) {
      _category.add(str);
      DocumentReference documentReference =
      FirebaseFirestore.instance.doc("SHOPS/DRESSSHOP/Category/$str");
      Map<String, dynamic>? data =
      await fireStoreService.getDocumentDetails(documentReference);

      if (data != null && data.isNotEmpty) {
        List<String> allValues = [];
        for (var value in data.values) {
          allValues.add(value);
        }
        _subCategory[str] = allValues;
      }
    }
    notifyListeners();
  }

  Future<void> isUserOwner() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference documentReference =
      FirebaseFirestore.instance.doc("/AdminDetails/DressShop");
      Map<String, dynamic>? data =
      await fireStoreService.getDocumentDetails(documentReference);
      Iterable ownerDetails = data!.values;
      if (ownerDetails.contains(user.email)) {
        _isOwner = true;
      } else {
        _isOwner = false;
      }
    } else {
      _isOwner = false;
    }
    notifyListeners();
  }
}
