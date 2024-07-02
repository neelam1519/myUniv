import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BusBookedHistory extends StatefulWidget {
  @override
  _BusBookedHistoryState createState() => _BusBookedHistoryState();
}

class _BusBookedHistoryState extends State<BusBookedHistory> {
  Utils utils = Utils();
  FireStoreService fireStoreService = FireStoreService();

  List<Map<String, dynamic>> _bookedHistory = [];
  bool _isLoading = true;
  bool _hasBookings = true;

  @override
  void initState() {
    super.initState();
    _fetchBookingHistory();
  }

  Future<void> _fetchBookingHistory() async {
    try {
      String userUID = await utils.getCurrentUserUID();
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

          setState(() {
            _bookedHistory = history;
            _isLoading = false;
            _hasBookings = history.isNotEmpty;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasBookings = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _hasBookings = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasBookings = false;
      });
      print('Error fetching booking history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booked History'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasBookings
          ? ListView.builder(
        itemCount: _bookedHistory.length,
        itemBuilder: (context, index) {
          var history = _bookedHistory[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text('Booking ID: ${history['BOOKING ID']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From: ${history['FROM']} \nTo: ${history['TO']}'),
                  Text('Pickup time: ${history['TIMINGS']}'),
                  if (history['CONFIRM TICKETS'] != null && history['CONFIRM TICKETS'] > 0)
                    Text('Confirmed tickets: ${history['CONFIRM TICKETS']}'),
                  if ((history['CONFIRM TICKETS'] == null || history['CONFIRM TICKETS'] == 0) &&
                      history['WAITING LIST TICKETS'] != null && history['WAITING LIST TICKETS'] > 0)
                    Text('Waiting list tickets: ${history['WAITING LIST TICKETS']}'),
                  Text('Date: ${history['DATE']}'),
                  Text('Amount paid: ${history['TOTAL COST']}'),
                ],
              ),
            ),
          );
        },
      )
          : Center(child: Text('No bookings found')),
    );
  }
}
