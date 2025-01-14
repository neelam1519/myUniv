import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;

import '../busbooking/paymentstatus.dart';
import 'busbookinggsheet.dart';

class RazorPayment extends ChangeNotifier {
  LoadingDialog loadingDialog = LoadingDialog();
  Utils utils = Utils();
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();
  FireStoreService fireStoreService = FireStoreService();
  Razorpay razorpay = Razorpay();
  String apiUrl = 'https://api.razorpay.com/v1/orders';
  static const _razorpayKey = 'rzp_live_kYGlb6Srm9dDRe';
  static const _apiSecret = 'GPRg9ri7zy4r7QeRe9lT2xUx';

  Map<String, dynamic> _busDetails = {};
  List<Map<String, dynamic>> _passengerDetails = [];
  String _email = "";
  String _mobileNumber = "";
  int _amountPaid = 0;

  initializeRazorpay(BuildContext context) async {
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      handlePaymentSuccess(response, context);
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      handlePaymentError(response,context);
    });

  }

  startPayment(int amount, String number, String email, Map<String, dynamic> busDetails, List<Map<String, dynamic>> passengerDetails) async {
    _busDetails = busDetails;
    _passengerDetails = passengerDetails;
    _email = email;
    _mobileNumber = number;
    _amountPaid = amount;

    if (!await utils.checkInternetConnection()) {
      utils.showToastMessage('Connect to the Internet');
      return;
    }
    loadingDialog.showDefaultLoading('Redirecting to Payment Page');
    final orderId = await createOrder(amount);
    loadingDialog.dismiss();
    print('Order ID: $orderId');
    if (orderId != null) {
      print('Order ID is not null');
      var options = {
        'key': _razorpayKey,
        'amount': amount * 100,
        'currency': 'INR',
        'name': 'FindAny',
        'description': 'Bus Booking',
        'prefill': {'contact': number, 'email': email},
        'order_id': orderId,
      };
      try {
        razorpay.open(options);
      } catch (e) {
        debugPrint('Razorpay Error: $e');
      }
    } else {
      print('Order is Null');
    }
  }

  Future<String?> createOrder(int amount) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode("$_razorpayKey:$_apiSecret"))}',
        },
        body: jsonEncode(<String, dynamic>{
          'amount': amount * 100,
          'currency': 'INR',
          'receipt': 'order_receipt_${DateTime.now().millisecondsSinceEpoch}',
          'payment_capture': 1,
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Got response code as 200');
        }
        final responseData = jsonDecode(response.body);
        return responseData['id'];
      } else {
        if (kDebugMode) {
          print('Failed to create order: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create order: $e');
      }
      return null;
    }
  }

  handlePaymentSuccess(PaymentSuccessResponse response, BuildContext context) async {
    loadingDialog.showDefaultLoading("Booking Ticket");

    if (kDebugMode) {
      print("Payment successful: ${response.paymentId}");
    }

    try {
      int? bookingID = await realTimeDatabase.incrementValue("TicketsCount");
      String ticketStatus = "WaitingList";

      Map<String, dynamic> data = {
        "Booking ID": bookingID,
        "Bus Number" : _busDetails["busNumber"],
        "Booking Time": DateTime.now(),
        "Email": _email,
        "Mobile Number": _mobileNumber,
        "From": _busDetails['from'],
        "TO": _busDetails['to'],
        "Bus Date": _busDetails['arrivalDate'],
        "Bus Time": _busDetails['arrivalTime'],
        "Ticket Count": _passengerDetails.length,
        "Passenger Details": _passengerDetails,
        "Total Amount": _amountPaid,
        "Payment ID": response.paymentId,
        "Ticket Status": ticketStatus,
      };

      String? uid = await utils.getCurrentUserUID();
      print('UID: $uid');

      DocumentReference userBookingReference = FirebaseFirestore.instance.doc("users/$uid/busbooking/${bookingID}");
      DocumentReference busReference = FirebaseFirestore.instance.doc("buses/${_busDetails['busNumber']}");

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot busSnapshot = await transaction.get(busReference);
        if (!busSnapshot.exists) {
          throw Exception("Bus does not exist!");
        }

        int availableSeats = busSnapshot['availableSeats'];
        int passengersCount = _passengerDetails.length;
        List<dynamic> confirmedTickets = busSnapshot['confirmedTickets'] ?? [];
        List<dynamic> waitingListTickets = busSnapshot['waitingListTickets'] ?? [];

        if (availableSeats >= passengersCount) {
          ticketStatus = "Confirmed";
          confirmedTickets.add(userBookingReference);
          transaction.update(busReference, {
            'availableSeats': availableSeats - passengersCount,
            'confirmedTickets': confirmedTickets,
          });
        } else {
          ticketStatus = "WaitingList";
          waitingListTickets.add(data);
          transaction.update(busReference, {
            'waitingListTickets': waitingListTickets,
          });
        }
      });

      data["Ticket Status"] = ticketStatus;
      await fireStoreService.uploadMapDataToFirestore(data, userBookingReference);
      await updateGoogleSheets(data);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStatus(
            busDetails: _busDetails,
            passengerDetails: _passengerDetails,
            isPaymentSuccessful: true,
          ),
        ),
      );

      loadingDialog.dismiss();
    } catch (e) {
      loadingDialog.dismiss();
      if (kDebugMode) {
        print("Error during payment success processing: $e");
      }
      // Show error dialog or retry logic
    }
  }

  handlePaymentError(PaymentFailureResponse response, BuildContext context) {
    if (kDebugMode) {
      print("Payment error: ${response.code} - ${response.message}");
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentStatus(
          busDetails: _busDetails,
          passengerDetails: _passengerDetails,
          isPaymentSuccessful: false, // Payment was successful
        ),
      ),
    );
  }

  // Function to update Google Sheets with the booking data
  Future<void> updateGoogleSheets(Map<String, dynamic> data) async {
    try {
      // Convert all values in the data map to strings
      final Map<String, String> stringData = data.map((key, value) => MapEntry(key, value?.toString() ?? ''));

      // Get the busID (or busNumber) from _busDetails
      String busID = _busDetails['busNumber']?.toString() ?? 'defaultBusID';

      // Update the Google Sheet for the specific busID
      await BusBookingGSheet.updateBusBookingSheet(stringData, busID);

      if (kDebugMode) {
        print("Google Sheet updated successfully.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to update Google Sheet: $e");
      }
    }
  }


}
