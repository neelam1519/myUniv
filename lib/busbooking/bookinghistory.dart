import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BookingHistory extends StatefulWidget {
  @override
  _BookingHistoryState createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String userId; // Store the userId here
  List<Map<String, dynamic>> bookingHistory = [];
  FireStoreService fireStoreService = FireStoreService();
  Utils utils = Utils();
  bool isLoading = true; // Flag to track loading state

  @override
  void initState() {
    super.initState();
    _initializeBookingHistory();
  }

  // Initialize the booking history by fetching the user ID and booking data
  Future<void> _initializeBookingHistory() async {
    userId = (await utils.getCurrentUserUID())!;
    print('UID: $userId');
    await fetchBookingHistory();
  }

  // Fetch booking history for the current user
  Future<void> fetchBookingHistory() async {
    try {
      CollectionReference collectionReference = FirebaseFirestore.instance.collection('users/$userId/busbooking');
      List<String> documents = await fireStoreService.getDocumentNames(collectionReference);
      print('Documents: $documents');

      List<Map<String, dynamic>> fetchedBookingHistory = [];

      for (String doc in documents) {
        Map<String, dynamic>? data = await fireStoreService.getDocumentDetails(collectionReference.doc(doc));

        if (data != null) {
          // Safely handle bookingTime conversion (check if it exists and is not null)
          DateTime? bookingTime;
          if (data['bookingTime'] != null) {
            // Convert to DateTime if bookingTime exists
            bookingTime = (data['Booking Time'] as Timestamp).toDate();
          }

          // Add data to the history list
          fetchedBookingHistory.add({
            'bookingID': doc,
            'from': data['From'] ?? 'Not provided',
            'to': data['TO'] ?? 'Not provided',
            'busDate': data['Bus Date'] ?? 'Not provided',
            'busTime': data['Bus Time'] ?? 'Not provided',
            'ticketCount': data['Ticket Count'] ?? 0,
            'totalAmount': data['Ticket Count'] ?? 0.0,
            'paymentID': data['Payment ID'] ?? 'Not provided',
            'bookingTime': bookingTime, // Store DateTime or null if no bookingTime
          });
        }
      }

      // Update the state once data is fetched
      setState(() {
        bookingHistory = fetchedBookingHistory;
        isLoading = false; // Set loading to false after data is fetched
      });

      print('Booking History: $bookingHistory');
    } catch (e) {
      print("Error fetching booking history: $e");
      setState(() {
        bookingHistory = [];
        isLoading = false; // Set loading to false in case of an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking History'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListView.builder(
            itemCount: 5, // Show 5 placeholder items while loading
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Container(
                    width: 150,
                    height: 20,
                    color: Colors.white,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Container(width: 200, height: 15, color: Colors.white),
                      SizedBox(height: 8),
                      Container(width: 250, height: 15, color: Colors.white),
                      SizedBox(height: 8),
                      Container(width: 180, height: 15, color: Colors.white),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      )
          : bookingHistory.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Booking History Found.\nBook Your Ticket!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: bookingHistory.length,
        itemBuilder: (context, index) {
          final booking = bookingHistory[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(
                "Booking ID: ${booking['bookingID']}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text('From: ${booking['from']}'),
                  Text('To: ${booking['to']}'),
                  Text('Date: ${booking['busDate']}'),
                  Text('Time: ${booking['busTime']}'),
                  Text('Tickets: ${booking['ticketCount']}'),
                  Text('Total: \$${booking['totalAmount']}'),
                  Text('Payment ID: ${booking['paymentID']}'),
                  booking['bookingTime'] != null
                      ? Text('Booking Time: ${booking['bookingTime']}')
                      : Text('Booking Time: Not available'),
                ],
              ),
              onTap: () {
                // Handle tap, navigate to booking details screen if needed
              },
            ),
          );
        },
      ),
    );
  }
}
