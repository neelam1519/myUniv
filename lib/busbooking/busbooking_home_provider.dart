import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../Firebase/firestore.dart';
import '../Firebase/realtimedatabase.dart';
import '../apis/busbookinggsheet.dart';
import '../utils/LoadingDialog.dart';
import '../utils/utils.dart';
import 'package:http/http.dart' as http;

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


  Razorpay razorpay = Razorpay();
  String apiUrl = 'https://api.razorpay.com/v1/orders';
  static const _razorpayKey = 'rzp_live_kYGlb6Srm9dDRe';
  static const _apiSecret = 'GPRg9ri7zy4r7QeRe9lT2xUx';

  initializeRazorpay() async {
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);
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
          'receipt': 'order_receipt_${DateTime
              .now()
              .millisecondsSinceEpoch}',
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
        if (kDebugMode) {
          print('Failed to create order response: ${response.body}');
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

  handlePaymentSuccess(PaymentSuccessResponse response) {
    if (kDebugMode) {
      print("Payment successful: ${response.paymentId}");
    }
  }

  handlePaymentError(PaymentFailureResponse response) {
    if (kDebugMode) {
      print("Payment error: ${response.code} - ${response.message}");
    }
  }

  handleExternalWallet(ExternalWalletResponse response) {
    if (kDebugMode) {
      print("External wallet: ${response.walletName}");
    }
  }


  startPayment(int amount, String number, String email) async {
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

  @override
  void dispose() {
    razorpay.clear();
    super.dispose();
  }
}