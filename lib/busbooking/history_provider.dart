import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Firebase/firestore.dart';
import '../utils/utils.dart';

class BusBookedHistoryProvider with ChangeNotifier {
  final Utils utils = Utils();
  final FireStoreService _fireStoreService = FireStoreService();

  List<Map<String, dynamic>> _bookedHistory = [];
  bool _isLoading = true;
  bool _hasBookings = true;

  List<Map<String, dynamic>> get bookedHistory => _bookedHistory;
  bool get isLoading => _isLoading;
  bool get hasBookings => _hasBookings;

  set bookedHistory(List<Map<String, dynamic>> value) {
    _bookedHistory = value;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set hasBookings(bool value) {
    _hasBookings = value;
    notifyListeners();
  }

  Future<void> fetchBookingHistory() async {
    try {
      String? userUID = await utils.getCurrentUserUID();
      DocumentReference ref = FirebaseFirestore.instance.doc('UserDetails/$userUID/BusBooking/BookedTickets');
      DocumentSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        Map<String, dynamic>? details = snapshot.data() as Map<String, dynamic>?;
        if (details != null) {
          List<DocumentReference> references = details.values.whereType<DocumentReference>().toList();
          List<Map<String, dynamic>> history = [];

          for (var reference in references) {
            var refSnapshot = await reference.get();
            if (refSnapshot.exists) {
              var data = refSnapshot.data() as Map<String, dynamic>;
              if (data.containsKey('DATE') && data['DATE'] is Timestamp) {
                Timestamp timestamp = data['DATE'];
                DateTime dateTime = timestamp.toDate();
                String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
                data['DATE'] = formattedDate;
              }
              history.add(data);
            }
          }

          history.sort((a, b) => b['BOOKING ID'].compareTo(a['BOOKING ID']));
          bookedHistory = history;
          isLoading = false;
          hasBookings = history.isNotEmpty;
        } else {
          isLoading = false;
          hasBookings = false;
        }
      } else {
        isLoading = false;
        hasBookings = false;
      }
    } catch (e) {
      isLoading = false;
      hasBookings = false;
      print('Error fetching booking history: $e');
    }
  }
}
