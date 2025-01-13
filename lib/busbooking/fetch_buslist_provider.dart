import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:async';  // For StreamSubscription

class FetchBusListProvider with ChangeNotifier {
  bool isLoading = false;
  List<Map<String, dynamic>> buses = [];
  StreamSubscription? _busSubscription;  // For holding the Firestore listener

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
          .where('arrivalDate', isEqualTo: selectedDate)
          .where('availableSeats', isGreaterThanOrEqualTo: 1)
          .where('status', isEqualTo: 'active')
          .get();

      // Map fetched data to list
      buses = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return {
          'from': data['from'],
          'to': data['to'],
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

      // Filter out buses with 0 available seats
      buses.removeWhere((bus) => bus['availableSeats'] == 0);

      // Sort buses by arrival time
      buses.sort((a, b) {
        DateTime arrivalA = DateFormat("h:mm a").parse(a['arrivalTime']);
        DateTime arrivalB = DateFormat("h:mm a").parse(b['arrivalTime']);
        return arrivalA.compareTo(arrivalB);
      });

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
      final difference = departure.difference(arrival);

      // Format duration as 'Xh Ym'
      return "${difference.inHours}h ${difference.inMinutes.remainder(60)}m";
    } catch (error) {
      print("Error calculating duration: $error");
      return "--";
    }
  }

  /// Listen for Firestore updates to the bus collection
  void listenToBusUpdates() {
    _busSubscription = FirebaseFirestore.instance
        .collection('buses')
        .where('status', isEqualTo: 'active') // You can filter further if needed
        .snapshots()
        .listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        print('Snapshot Change');
        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
          print('Snapshot Change updating bus');
          _updateBus(change.doc.id, change.doc.data()!);
        }
      });
    });
  }

  // Method to update bus info based on Firestore document changes
  void _updateBus(String busId, Map<String, dynamic> updatedData) {
    // Ensure busId and busNumber are both strings (or both are integers)
    int? busIndex = buses.indexWhere((bus) => bus['busNumber'].toString() == busId.toString());

    if (busIndex != -1) {
      buses[busIndex] = {
        'from': updatedData['from'],
        'to': updatedData['to'],
        'busNumber': updatedData['busNumber'],
        'departureTime': updatedData['departureTime'],
        'departureDate': updatedData['departureDate'],
        'arrivalTime': updatedData['arrivalTime'],
        'arrivalDate': updatedData['arrivalDate'],
        'totalSeats': updatedData['totalSeats'],
        'availableSeats': updatedData['availableSeats'],
        'price': updatedData['price'],
        'duration': _calculateDuration(updatedData['departureTime'], updatedData['arrivalTime']),
        'seatsLeft': updatedData['availableSeats'],
      };

      // Remove bus if availableSeats is 0
      if (buses[busIndex]['availableSeats'] == 0) {
        buses.removeAt(busIndex);
      }

      print("updated busses: $buses");

      notifyListeners();
    } else {
      print('Bus with ID $busId not found in the list.');
    }
  }

  // Stop listening to the Firestore updates
  void stopListeningToBusUpdates() {
    _busSubscription?.cancel();  // Cancel the subscription to stop listening
    print("Stopped listening to bus updates.");
  }
}
