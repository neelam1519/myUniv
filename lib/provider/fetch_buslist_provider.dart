import 'package:flutter/material.dart';

class FetchBuslistProvider with ChangeNotifier{

  int? _count = 10;

  int? get count => _count;


  set count(int? value){
    _count = value;
    notifyListeners();
  }

  Future<void> fetchBuses() async {
    await Future.delayed(const Duration(seconds: 2));
    notifyListeners();
  }
}