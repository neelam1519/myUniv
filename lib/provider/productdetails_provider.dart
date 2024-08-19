import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ProductDetailsProvider extends ChangeNotifier {
  DocumentSnapshot? documentSnapshot;
  List<DocumentSnapshot> products = [];

  List<DocumentSnapshot> get _products => products;
  DocumentSnapshot? get detailsSnapshot => documentSnapshot;

  void updateProductSnapshots(List<DocumentSnapshot> docSnapshot){
    products = docSnapshot;
    notifyListeners();
  }

  List<DocumentSnapshot> getProductsSnapshots(){
    return products;
  }

  void removeProductByReference(DocumentReference productRef) {
    products.removeWhere((product) => product.reference == productRef);
    notifyListeners();
  }

  void addOrUpdateProductSnapshot(DocumentSnapshot docSnapshot) {
    int index = products.indexWhere((product) => product.id == docSnapshot.id);
    if (index != -1) {
      products[index] = docSnapshot;
    } else {
      products.add(docSnapshot);
    }
    notifyListeners();
  }


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
