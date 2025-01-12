import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class FetchBusListProvider with ChangeNotifier {
  bool isLoading = false;
  List<Map<String, dynamic>> buses = [];

  /// Fetch bus list based on filters
  Future<void> fetchBusList({
    required String fromLocation,
    required String toLocation,
    required String selectedDate,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      // Reference to Firestore collection
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('buses')
          .where('from', isEqualTo: fromLocation)
          .where('to', isEqualTo: toLocation)
          .where('departureDate', isEqualTo: selectedDate)
          .where('status', isEqualTo: 'active')
          .get();

      // Map fetched data to list
      buses = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return {
          'from' :data['from'],
          'to' : data['to'],
          'busNumber': data['busNumber'],
          'departureTime': data['departureTime'],
          'departureDate': data['departureDate'],
          'arrivalTime': data['arrivalTime'],
          'arrivalDate': data['arrivalDate'],
          'totalSeats': data['totalSeats'],
          'availableSeats': data['availableSeats'],
          'price': data['price'],
          'duration': _calculateDuration(data['departureTime'], data['arrivalTime']),
          'seatsLeft': data['availableSeats'],
        };
      }).toList();

      print("Buses: $buses");
    } catch (error) {
      if (kDebugMode) {
        print("Error fetching buses: $error");
      }
    }

    isLoading = false;
    notifyListeners();
  }

  String _calculateDuration(String departureTime, String arrivalTime) {
    print('Departure Time: $departureTime   Arrival Time: $arrivalTime');
    try {
      final timeFormat = DateFormat("h:mm a"); // 12-hour format with AM/PM
      final departure = timeFormat.parse(departureTime);
      final arrival = timeFormat.parse(arrivalTime);

      // Calculate the difference
      final difference = arrival.difference(departure);

      // Format duration as 'Xh Ym'
      return "${difference.inHours}h ${difference.inMinutes.remainder(60)}m";
    } catch (error) {
      print("Error calculating duration: $error");
      return "--";
    }
  }
}
