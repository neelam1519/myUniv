import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../Firebase/firestore.dart';
import '../Firebase/realtimedatabase.dart';
import '../apis/busbookinggsheet.dart';
import '../utils/LoadingDialog.dart';
import '../utils/utils.dart';

class BusBookingHomeProvider with ChangeNotifier {
  LoadingDialog loadingDialog = LoadingDialog();
  FireStoreService fireStoreService = FireStoreService();
  BusBookingGSheet busBookingGSheet = BusBookingGSheet();
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();

  Utils utils = Utils();

  List<String> fromPlaces = [];
  List<String> toPlaces = [];

  // The selected values
  String? selectedFrom;
  String? selectedTo;
  DateTime selectedDate = DateTime.now();
  String? selectedTime;

  Future<void> fetchBusDetails() async {
    try {
      // Fetch the bus data from Firestore (or any other source you use)
      QuerySnapshot busesSnapshot = await FirebaseFirestore.instance.collection('buses').get();

      // Create a Set to hold unique from and to locations
      Set<String> fromSet = Set<String>();
      Set<String> toSet = Set<String>();

      // Iterate through the buses data and extract locations
      for (var bus in busesSnapshot.docs) {
        String from = bus['from'] ?? '';
        String to = bus['to'] ?? '';

        if (from.isNotEmpty) fromSet.add(from);
        if (to.isNotEmpty) toSet.add(to);
      }

      // Update the provider's lists
      fromPlaces = fromSet.toList();
      toPlaces = toSet.toList();

      // Notify listeners to rebuild the widget
      notifyListeners();
    } catch (e) {
      print('Error fetching bus details: $e');
    }
  }

  // Method to update the selected from location
   updateSelectedFrom(String? newFrom) {
    selectedFrom = newFrom;
    selectedTo = null; // Reset to location when from location changes
    selectedTime = null;
    notifyListeners();
  }

  // Method to update the selected to location
   updateSelectedTo(String? newTo) {
    selectedTo = newTo;
    selectedTime = null;
    notifyListeners();
  }

   updateSelectedDate(DateTime newDate) {
    selectedDate = newDate;
    notifyListeners();
  }

  // Method to update the selected time
  void updateSelectedTime(String? newTime) {
    selectedTime = newTime;
    notifyListeners();
  }



  @override
  void dispose() {
    super.dispose();
  }
}