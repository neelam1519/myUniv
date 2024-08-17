import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ProductDetailsProvider extends ChangeNotifier {
  DocumentSnapshot? documentSnapshot;

  DocumentSnapshot? get detailsSnapshot => documentSnapshot;

  void updateDetailsSnapshot(DocumentSnapshot? docSnapshot) {
    documentSnapshot = docSnapshot;
    notifyListeners();
  }

  DocumentSnapshot? getDetailsSnapshot() {
    if (documentSnapshot != null) {
      print("Get DocumentSnapShot Provider: ${documentSnapshot!.data()}");
    } else {
      print("Get DocumentSnapShot Provider: null");
    }
    return documentSnapshot;
  }
}
