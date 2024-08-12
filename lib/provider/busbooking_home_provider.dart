import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../Firebase/firestore.dart';
import '../Firebase/realtimedatabase.dart';
import '../apis/busbookinggsheet.dart';
import '../services/sendnotification.dart';
import '../utils/LoadingDialog.dart';
import '../utils/utils.dart';
import 'package:http/http.dart' as http;

class BusBookingHomeProvider with ChangeNotifier {
  LoadingDialog loadingDialog = LoadingDialog();
  FireStoreService fireStoreService = FireStoreService();
  BusBookingGSheet busBookingGSheet = BusBookingGSheet();
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();
  NotificationService notificationService = NotificationService();
  Utils utils = Utils();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  String? _selectedFrom;
  String? _selectedTo;
  String? _selectedDateFormatted;
  DateTime? _selectedDate;
  String? _selectedTiming;
  double? _travelCost;
  List<String> _fromPlaces = [];
  List<String> _toPlaces = [];
  List<String> _timings = [];
  List<String> _availableDates = [];
  String _busID = "";
  int _waitingListSeats = 0;
  int _availableSeats = 0;
  String? _announcementText = "";
  String? _message = "";
  String? _contactus = "";

  Map<String, dynamic>? _detailsData = {};
  Map<String, dynamic>? _placesData = {};
  Map<String, Map<String, List<String>>> _dateToTimingsMap = {};

  DocumentReference _placesDoc = FirebaseFirestore.instance.doc("busbooking/places");
  DocumentReference _detailsDoc = FirebaseFirestore.instance.doc("busbooking/Details");

  final TextEditingController _costController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  String? _mobileNumber = "";
  String _trainNo = "";

  final List<Map<String, String?>> _people = [];

  Razorpay razorpay = Razorpay();
  String apiUrl = 'https://api.razorpay.com/v1/orders';
  static const _razorpayKey = 'rzp_live_kYGlb6Srm9dDRe';
  static const _apiSecret = 'GPRg9ri7zy4r7QeRe9lT2xUx';

  // Getters and Setters
  String? get selectedFrom => _selectedFrom;

  set selectedFrom(String? value) {
    _selectedFrom = value;
    notifyListeners();
  }

  String? get selectedTo => _selectedTo;

  set selectedTo(String? value) {
    _selectedTo = value;
    notifyListeners();
  }

  String? get mobileNumber => _mobileNumber;

  set mobileNumber(String? value) {
    _mobileNumber = value;
    notifyListeners();
  }

  String? get selectedDateFormatted => _selectedDateFormatted;

  set selectedDateFormatted(String? value) {
    _selectedDateFormatted = value;
    notifyListeners();
  }

  DateTime? get selectedDate => _selectedDate;

  set selectedDate(DateTime? value) {
    _selectedDate = value;
    notifyListeners();
  }

  String? get selectedTiming => _selectedTiming;

  set selectedTiming(String? value) {
    _selectedTiming = value;
    notifyListeners();
  }

  double? get travelCost => _travelCost;

  set travelCost(double? value) {
    _travelCost = value;
    notifyListeners();
  }

  List<String> get fromPlaces => _fromPlaces;

  set fromPlaces(List<String> value) {
    _fromPlaces = value;
    notifyListeners();
  }

  List<String> get toPlaces => _toPlaces;

  set toPlaces(List<String> value) {
    _toPlaces = value;
    notifyListeners();
  }

  List<String> get timings => _timings;

  set timings(List<String> value) {
    _timings = value;
    notifyListeners();
  }

  List<String> get availableDates => _availableDates;

  set availableDates(List<String> value) {
    _availableDates = value;
    notifyListeners();
  }

  String get busID => _busID;

  set busID(String value) {
    _busID = value;
    notifyListeners();
  }

  int get waitingListSeats => _waitingListSeats;

  set waitingListSeats(int value) {
    _waitingListSeats = value;
    notifyListeners();
  }

  int get availableSeats => _availableSeats;

  set availableSeats(int value) {
    _availableSeats = value;
    notifyListeners();
  }

  String? get announcementText => _announcementText;

  set announcementText(String? value) {
    _announcementText = value;
    notifyListeners();
  }

  String? get message => _message;

  set message(String? value) {
    _message = value;
    notifyListeners();
  }

  String? get contactus => _contactus;

  set contactus(String? value) {
    _contactus = value;
    notifyListeners();
  }

  Map<String, dynamic>? get detailsData => _detailsData;

  set detailsData(Map<String, dynamic>? value) {
    _detailsData = value;
    notifyListeners();
  }

  Map<String, dynamic>? get placesData => _placesData;

  set placesData(Map<String, dynamic>? value) {
    _placesData = value;
    notifyListeners();
  }

  Map<String, Map<String, List<String>>> get dateToTimingsMap => _dateToTimingsMap;

  set dateToTimingsMap(Map<String, Map<String, List<String>>> value) {
    _dateToTimingsMap = value;
    notifyListeners();
  }

  DocumentReference get placesDoc => _placesDoc;

  set placesDoc(DocumentReference value) {
    _placesDoc = value;
    notifyListeners();
  }

  DocumentReference get detailsDoc => _detailsDoc;

  set detailsDoc(DocumentReference value) {
    _detailsDoc = value;
    notifyListeners();
  }

  TextEditingController get costController => _costController;

  TextEditingController get totalCostController => _totalCostController;

  DateFormat get timeFormat => _timeFormat;


  String get trainNo => _trainNo;

  set trainNo(String value) {
    _trainNo = value;
    notifyListeners();
  }

  List<Map<String, String?>> get people => _people;

  // Add the rest of your methods here...
  listen(String busID) async {
    loadingDialog.showDefaultLoading("Getting Seats Availability...");
    final DatabaseReference databaseReference = _database.ref('BusBookingTickets/$busID');

    databaseReference.onValue.listen((event) {
      final dataSnapshot = event.snapshot;
      if (dataSnapshot.exists) {
        _availableSeats = dataSnapshot
            .child('Available')
            .value as int;
        _waitingListSeats = dataSnapshot
            .child('WaitingList')
            .value as int;
        notifyListeners();

        if (kDebugMode) {
          print('Available Seats: $_availableSeats');
        }
        if (kDebugMode) {
          print('Waiting List: $_waitingListSeats');
        }
      } else {
        if (kDebugMode) {
          print('No data available for busID: $busID');
        }
      }
    });

    _availableSeats = await realTimeDatabase.getCurrentValue('BusBookingTickets/$busID/Available') ?? 0;
    _waitingListSeats = await realTimeDatabase.getCurrentValue('BusBookingTickets/$busID/WaitingList') ?? 0;
    notifyListeners();
    loadingDialog.dismiss();
  }

  fetchAnnouncementText() async {
    final DatabaseReference announcementRef = _database.ref('BusBookingTickets/Announcements');
    announcementRef.onValue.listen((event) {
      final DataSnapshot snapshot = event.snapshot;
      if (snapshot.exists) {
        _announcementText = snapshot.value as String?;
        notifyListeners();
      } else {
        _announcementText = null;
        notifyListeners();
      }
    });

    final DatabaseReference messageText = _database.ref('BusBookingTickets/message');
    messageText.onValue.listen((event) {
      final DataSnapshot snapshot = event.snapshot;
      if (snapshot.exists) {
        _message = snapshot.value as String?;
        notifyListeners();
      } else {
        _message = null;
        notifyListeners();
      }
    });

    final DatabaseReference contactText = _database.ref('BusBookingTickets/contact');
    contactText.onValue.listen((event) {
      final DataSnapshot snapshot = event.snapshot;
      if (snapshot.exists) {
        _contactus = snapshot.value as String?;
        notifyListeners();
      } else {
        _contactus = null;
        notifyListeners();
      }
    });
  }

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

  _fetchDetails(String fromPlace, String toPlace) async {
    try {
      Map<String, dynamic>? detailsData = await FireStoreService().getDocumentDetails(detailsDoc);
      print('Details Data: $detailsData');
      if (detailsData != null && detailsData.containsKey(fromPlace)) {
        Map<String, dynamic> details = detailsData[fromPlace][toPlace];

        print("Fetched Details: $details");

        Map<String, dynamic> datesData = details['Dates'];

        Set<String> availableDates = {};
        dateToTimingsMap.clear();

        final dateFormat = DateFormat('dd-MM-yyyy');

        datesData.forEach((id, timestamp) {
          DateTime dateTime = (timestamp as Timestamp).toDate();
          String date = dateFormat.format(dateTime);
          String time = timeFormat.format(dateTime); // Changed to use the new time format
          availableDates.add(date);

          if (!dateToTimingsMap.containsKey(date)) {
            dateToTimingsMap[date] = {};
          }

          if (!dateToTimingsMap[date]!.containsKey(id)) {
            dateToTimingsMap[date]![id] = [];
          }

          dateToTimingsMap[date]![id]!.add(time);
        });

        // Sort dates
        _availableDates = availableDates.toList()
          ..sort((a, b) => dateFormat.parse(a).compareTo(dateFormat.parse(b)));
        _selectedDateFormatted = _availableDates.isNotEmpty ? _availableDates.first : null;
        _selectedDate = _selectedDateFormatted != null ? dateFormat.parse(_selectedDateFormatted!) : null;

        updateTimingsForSelectedDate();

        _travelCost = double.tryParse(details['Cost'].toString()) ?? 0;
        _selectedTiming = _timings.isNotEmpty ? _timings.first : null;
        _costController.text = _travelCost != null ? '₹${_travelCost!.toStringAsFixed(2)}' : 'N/A';
        _updateTotalCost();
      } else {
        _availableDates = [];
        _timings = [];
        _travelCost = null;
        _costController.text = 'N/A';
        _updateTotalCost();
      }
    } catch (e) {
      print("error is ${e.toString()}");
    } finally {
      loadingDialog.dismiss();
    }
  }

  updateTimingsForSelectedDate() {
    final dateFormat = DateFormat('dd-MM-yyyy');

    if (_selectedDate != null) {
      String selectedDateString = dateFormat.format(_selectedDate!);
      if (dateToTimingsMap.containsKey(selectedDateString)) {
        _timings = dateToTimingsMap[selectedDateString]!.values.expand((timings) => timings).toList();
        // Sort timings
        _timings.sort((a, b) => timeFormat.parse(a).compareTo(timeFormat.parse(b)));
      } else {
        _timings = [];
      }
      _selectedTiming = _timings.isNotEmpty ? _timings.first : null;
      updateBusID();
    }
  }

  _updateTotalCost() {
    double totalCost = (_travelCost ?? 0) * _people.length;
    _totalCostController.text = '₹${totalCost.toStringAsFixed(2)}';
  }


  addPerson() {
    _people.add({'name': null, 'gender': null});
    _updateTotalCost();
    notifyListeners();
  }

  removePerson(int index) {
    _people.removeAt(index);
    _updateTotalCost();
    notifyListeners();
  }


  Future<void> searchBuses(BuildContext context) async {
    if (_selectedFrom == null || _selectedTo == null || _selectedDate == null || _selectedTiming == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (kDebugMode) {
      print('People: $_people');
    }

    for (var person in _people) {
      if (person['name'] == null || person['gender'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill the Persons details')),
        );
        return;
      }
    }

    if (_people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add the Persons details')),
      );
      return;
    }

    if (!utils.isValidMobileNumber(_mobileNumber!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter Valid Mobile Number")),
      );
      return;
    }

    String? email = await utils.getCurrentUserEmail();
    String amt = _totalCostController.text.replaceAll("₹", "");
    double amount = double.parse(amt);
    int cost = amount.round();
    startPayment(cost, _mobileNumber!, email ?? "Email Not Found");
    if (kDebugMode) {
      print('Details $_people $_selectedFrom  $_selectedTo $_selectedDate  $_selectedTiming');
    }
  }

  updateBusID() {
    final dateFormat = DateFormat('dd-MM-yyyy');

    if (_selectedDate != null && _selectedTiming != null) {
      String selectedDateString = dateFormat.format(_selectedDate!);
      if (dateToTimingsMap.containsKey(selectedDateString)) {
        Map<String, List<String>> timingsMap = dateToTimingsMap[selectedDateString]!;
        for (String id in timingsMap.keys) {
          if (timingsMap[id]!.contains(_selectedTiming)) {
            busID = id;
            listen(busID);
            print('Updated BusID: $busID');
            notifyListeners();
            return;
          }
        }
      }
    }
    busID = "";
    notifyListeners();
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

  fetchFromPlaces() async {
    loadingDialog.showDefaultLoading("Getting data...");
    try {
      placesData = await fireStoreService.getDocumentDetails(placesDoc);

      if (placesData != null && placesData!.isNotEmpty) {
        _fromPlaces = List<String>.from(placesData!['from'] ?? []);
        _toPlaces = List<String>.from(placesData!['to'] ?? []);
        _selectedFrom = _fromPlaces.isNotEmpty ? _fromPlaces.first : null;
        _selectedTo = _toPlaces.isNotEmpty ? _toPlaces.first : null;
        notifyListeners();
        if (_selectedFrom != null && _selectedTo != null) {
          _fetchDetails(_selectedFrom!, _selectedTo!);
        }
      } else {
        print('Empty Data Found');
      }
    } catch (e) {
      print(e);
    } finally {
      loadingDialog.dismiss();
    }
  }

  fetchDetails(String fromPlace, String toPlace) async {
    try {
      Map<String, dynamic>? detailsData = await FireStoreService().getDocumentDetails(detailsDoc);
      print('Details Data: $detailsData');
      if (detailsData != null && detailsData.containsKey(fromPlace)) {
        Map<String, dynamic> details = detailsData[fromPlace][toPlace];

        print("Fetched Details: $details");

        Map<String, dynamic> datesData = details['Dates'];

        Set<String> availableDates = {};
        dateToTimingsMap.clear();

        final dateFormat = DateFormat('dd-MM-yyyy');

        datesData.forEach((id, timestamp) {
          DateTime dateTime = (timestamp as Timestamp).toDate();
          String date = dateFormat.format(dateTime);
          String time = timeFormat.format(dateTime); // Changed to use the new time format
          availableDates.add(date);

          if (!dateToTimingsMap.containsKey(date)) {
            dateToTimingsMap[date] = {};
          }

          if (!dateToTimingsMap[date]!.containsKey(id)) {
            dateToTimingsMap[date]![id] = [];
          }

          dateToTimingsMap[date]![id]!.add(time);
        });

        // Sort dates
        _availableDates = availableDates.toList()
          ..sort((a, b) => dateFormat.parse(a).compareTo(dateFormat.parse(b)));
        _selectedDateFormatted = _availableDates.isNotEmpty ? _availableDates.first : null;
        _selectedDate = _selectedDateFormatted != null ? dateFormat.parse(_selectedDateFormatted!) : null;

        updateTimingsForSelectedDate();

        _travelCost = double.tryParse(details['Cost'].toString()) ?? 0;
        _selectedTiming = _timings.isNotEmpty ? _timings.first : null;
        _costController.text = _travelCost != null ? '₹${_travelCost!.toStringAsFixed(2)}' : 'N/A';
        _updateTotalCost();
        notifyListeners();
      } else {
        print('No Data in fetchDetails');
        _availableDates = [];
        _timings = [];
        _travelCost = null;
        _costController.text = 'N/A';
        _updateTotalCost();
        notifyListeners();
      }
    } catch (e) {
      print("Fetch Details: $e");
    } finally {
      loadingDialog.dismiss();
    }
  }

  @override
  void dispose() {
    _costController.dispose();
    _totalCostController.dispose();
    razorpay.clear();
    super.dispose();
  }
}

// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import '../Firebase/firestore.dart';
// import '../Firebase/realtimedatabase.dart';
// import '../apis/busbookinggsheet.dart';
// import '../services/sendnotification.dart';
// import '../utils/LoadingDialog.dart';
// import '../utils/utils.dart';
// import 'package:http/http.dart' as http;
//
// class BusBookingHomeProvider with ChangeNotifier {
//   LoadingDialog loadingDialog = LoadingDialog();
//   FireStoreService fireStoreService = FireStoreService();
//   BusBookingGSheet busBookingGSheet = BusBookingGSheet();
//   RealTimeDatabase realTimeDatabase = RealTimeDatabase();
//   NotificationService notificationService = NotificationService();
//   Utils utils = Utils();
//
//   final FirebaseDatabase _database = FirebaseDatabase.instance;
//
//   String? _selectedFrom;
//   String? _selectedTo;
//   String? _selectedDateFormatted;
//   DateTime? _selectedDate;
//   String? _selectedTiming;
//   double? _travelCost;
//   List<String> _fromPlaces = [];
//   List<String> _toPlaces = [];
//   List<String> _timings = [];
//   List<String> _availableDates = [];
//   String busID = "";
//   int _waitingListSeats = 0;
//   int _availableSeats = 0;
//   String? _announcementText = "";
//   String? message = "";
//   String? contactus = "";
//
//   Map<String, dynamic>? detailsData = {};
//   Map<String, dynamic>? placesData = {};
//   Map<String, Map<String, List<String>>> dateToTimingsMap = {};
//
//   DocumentReference placesDoc = FirebaseFirestore.instance.doc("busbooking/places");
//   DocumentReference detailsDoc = FirebaseFirestore.instance.doc("busbooking/Details");
//
//   final TextEditingController _costController = TextEditingController();
//   final TextEditingController _totalCostController = TextEditingController();
//   final timeFormat = DateFormat('hh:mm a');
//   String _mobileNumber = "";
//   String trainNo = "";
//
//   final List<Map<String, String?>> _people = [];
//
//   Razorpay razorpay = Razorpay();
//   String apiUrl = 'https://api.razorpay.com/v1/orders';
//   static const _razorpayKey = 'rzp_live_kYGlb6Srm9dDRe';
//   static const _apiSecret = 'GPRg9ri7zy4r7QeRe9lT2xUx';
//
//
//
//
//   Future<void> listen(String busID) async {
//     loadingDialog.showDefaultLoading("Getting Seats Availability...");
//     final DatabaseReference databaseReference = _database.ref('BusBookingTickets/$busID');
//
//     databaseReference.onValue.listen((event) {
//       final dataSnapshot = event.snapshot;
//       if (dataSnapshot.exists) {
//         _availableSeats = dataSnapshot.child('Available').value as int;
//         _waitingListSeats = dataSnapshot.child('WaitingList').value as int;
//         notifyListeners();
//         if (kDebugMode) {
//           print('Available Seats: $_availableSeats');
//         }
//         if (kDebugMode) {
//           print('Waiting List: $_waitingListSeats');
//         }
//       } else {
//         if (kDebugMode) {
//           print('No data available for busID: $busID');
//         }
//       }
//     });
//
//     _availableSeats = await realTimeDatabase.getCurrentValue('BusBookingTickets/$busID/Available') ?? 0;
//     _waitingListSeats = await realTimeDatabase.getCurrentValue('BusBookingTickets/$busID/WaitingList') ?? 0;
//     notifyListeners();
//     loadingDialog.dismiss();
//   }
//
//   Future<void> _fetchAnnouncementText() async {
//     final DatabaseReference announcementRef = _database.ref('BusBookingTickets/Announcements');
//     announcementRef.onValue.listen((event) {
//       final DataSnapshot snapshot = event.snapshot;
//       if (snapshot.exists) {
//         _announcementText = snapshot.value as String?;
//         notifyListeners();
//       } else {
//         _announcementText = null;
//         notifyListeners();
//       }
//     });
//
//     final DatabaseReference messageText = _database.ref('BusBookingTickets/message');
//     messageText.onValue.listen((event) {
//       final DataSnapshot snapshot = event.snapshot;
//       if (snapshot.exists) {
//         message = snapshot.value as String?;
//         notifyListeners();
//       } else {
//         message = null;
//         notifyListeners();
//       }
//     });
//
//     final DatabaseReference contactText = _database.ref('BusBookingTickets/contact');
//     contactText.onValue.listen((event) {
//       final DataSnapshot snapshot = event.snapshot;
//       if (snapshot.exists) {
//         contactus = snapshot.value as String?;
//         notifyListeners();
//       } else {
//         contactus = null;
//         notifyListeners();
//       }
//     });
//   }
//
//   initializeRazorpay() async {
//     razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
//     razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
//     razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);
//   }
//
//   Future<String?> createOrder(int amount) async {
//     try {
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: <String, String>{
//           'Content-Type': 'application/json',
//           'Authorization': 'Basic ${base64Encode(utf8.encode("$_razorpayKey:$_apiSecret"))}',
//         },
//         body: jsonEncode(<String, dynamic>{
//           'amount': amount * 100,
//           'currency': 'INR',
//           'receipt': 'order_receipt_${DateTime.now().millisecondsSinceEpoch}',
//           'payment_capture': 1,
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         if (kDebugMode) {
//           print('Got response code as 200');
//         }
//         final responseData = jsonDecode(response.body);
//         return responseData['id'];
//       } else {
//         if (kDebugMode) {
//           print('Failed to create order: ${response.statusCode}');
//         }
//         if (kDebugMode) {
//           print('Response body: ${response.body}');
//         }
//         return null;
//       }
//     } catch (e) {
//       print('Error creating order: $e');
//       return null;
//     }
//   }
//
//   void startPayment(int amount, String number, String email) async {
//     if (!await utils.checkInternetConnection()) {
//       utils.showToastMessage('Connect to the Internet');
//       return;
//     }
//     loadingDialog.showDefaultLoading('Redirecting to Payment Page');
//     final orderId = await createOrder(amount);
//     loadingDialog.dismiss();
//     print('Order ID: $orderId');
//     if (orderId != null) {
//       print('Order ID is not null');
//       var options = {
//         'key': _razorpayKey,
//         'amount': amount * 100,
//         'currency': 'INR',
//         'name': 'FindAny',
//         'description': 'Bus Booking',
//         'prefill': {'contact': number, 'email': email},
//         'order_id': orderId,
//       };
//       try {
//         razorpay.open(options);
//       } catch (e) {
//         debugPrint('Razorpay Error: $e');
//       }
//     } else {
//       print('Order is Null');
//     }
//   }
//
//   Future<void> handlePaymentSuccess(PaymentSuccessResponse response) async {
//     if (kDebugMode) {
//       print('razorpay successful ${response.paymentId}');
//     }
//     await updateTickets(_people.length, response);
//   }
//
//   void handlePaymentError(PaymentFailureResponse response) {
//     if (kDebugMode) {
//       print('razorpay unsuccessful: ${response.message}');
//     }
//     utils.showToastMessage('Payment unsuccessful');
//   }
//
//   void handleExternalWallet(ExternalWalletResponse response) {
//     if (kDebugMode) {
//       print('razorpay External wallet ${response.walletName}');
//     }
//   }
//
//   Future<void> updateTickets(int peopleCount, PaymentSuccessResponse response) async {
//     final DatabaseReference ticketRef = _database.ref('BusBookingTickets/$busID');
//     String availableTickets = 'BusBookingTickets/$busID/Available';
//     String waitingListTickets = 'BusBookingTickets/$busID/WaitingList';
//
//     int currentTickets = (await realTimeDatabase.getCurrentValue(availableTickets) as int?) ?? 0;
//     int currentWaitingList = (await realTimeDatabase.getCurrentValue(waitingListTickets) as int?) ?? 0;
//     int waitingListCount = 0;
//     int confirmTicketCount = 0;
//
//     if (currentTickets <= 0) {
//       currentWaitingList += peopleCount;
//       await ticketRef.child('WaitingList').set(currentWaitingList);
//       waitingListCount = peopleCount;
//       if (kDebugMode) {
//         print('All tickets are sold out. Added $peopleCount people to the waiting list.');
//       }
//     } else if (peopleCount <= currentTickets) {
//       currentTickets -= peopleCount;
//       await ticketRef.child('Available').set(currentTickets);
//       confirmTicketCount = peopleCount;
//       if (kDebugMode) {
//         print('Booked $peopleCount tickets. Remaining tickets: $currentTickets');
//       }
//     } else {
//       int bookedTickets = currentTickets;
//       int waitingListAddition = peopleCount - currentTickets;
//       currentTickets = 0;
//       currentWaitingList += waitingListAddition;
//
//       await ticketRef.child('Available').set(currentTickets);
//       await ticketRef.child('WaitingList').set(currentWaitingList);
//
//       waitingListCount = waitingListAddition;
//       confirmTicketCount = bookedTickets;
//
//       if (kDebugMode) {
//         print('Booked $bookedTickets tickets. Added $waitingListAddition people to the waiting list.');
//       }
//     }
//
//     await uploadData(response, confirmTicketCount, waitingListCount);
//   }
//
//
//   Future<void> uploadData(PaymentSuccessResponse response, int confirmTickets, int waitingListTickets) async {
//     loadingDialog.showDefaultLoading('Booking Ticket...');
//     if (kDebugMode) {
//       print('Response: ${response.data}');
//     }
//
//     String? email = await utils.getCurrentUserEmail();
//     String regNo = utils.removeEmailDomain(email!);
//
//     int? bookingID = await realTimeDatabase.incrementValue("BusBookingTickets/TicketID");
//
//     List<dynamic> data = [
//       regNo,
//       _mobileNumber,
//       email,
//       _selectedFrom.toString(),
//       _selectedTo.toString(),
//       _selectedDate.toString(),
//       _selectedTiming.toString(),
//       trainNo,
//       _totalCostController.text,
//       response.paymentId ?? "",
//       bookingID,
//       "$confirmTickets - $waitingListTickets",
//       _people.toString()
//     ];
//
//     busBookingGSheet.updateCell(data,busID);
//
//     Map<String, dynamic> busBookingData = {
//       'REGISTRATION NUMBER': regNo,
//       'MOBILE NUMBER': _mobileNumber,
//       'FROM': _selectedFrom,
//       'TO': _selectedTo,
//       'DATE': _selectedDate,
//       'TIMINGS': _selectedTiming,
//       'TRAIN NO': trainNo,
//       'TOTAL COST': _totalCostController.text,
//       'PAYMENT ID': response.paymentId,
//       'PEOPLE LIST': _people,
//       'TICKET COUNT': _people.length,
//       'CONFIRM TICKETS': confirmTickets,
//       'WAITING LIST TICKETS': waitingListTickets,
//       'BOOKING ID': bookingID
//     };
//
//     DocumentReference historyRef = FirebaseFirestore.instance.doc("UserDetails/${await utils.getCurrentUserUID()}/BusBooking/BookedTickets");
//
//     DocumentReference busDetailsRef = FirebaseFirestore.instance.doc('/busbooking/BookingIDs/$busID/$bookingID');
//     await fireStoreService.uploadMapDataToFirestore(busBookingData, busDetailsRef);
//     Map<String, dynamic> historyData = {bookingID.toString(): busDetailsRef};
//     await fireStoreService.uploadMapDataToFirestore(historyData, historyRef);
//     utils.showToastMessage('Ticket is booked. Check the history');
//
//     DocumentReference tokenRef = FirebaseFirestore.instance.doc('AdminDetails/BusBooking');
//     List<String> tokens = await utils.getSpecificTokens(tokenRef);
//
//     notificationService.sendNotification(tokens, "Bus Booking", 'Bus is booked with the ID: $bookingID', {});
//
//     String? token = await utils.getToken();
//
//     notificationService.sendNotification([token], "Bus Booking", 'Your bus is booked with the ID $bookingID. You can check your booking details in the history', {});
//     loadingDialog.dismiss();
//   }
//
//
//   @override
//   void dispose() {
//     razorpay.clear();
//     _costController.dispose();
//     _totalCostController.dispose();
//     super.dispose();
//   }
// }
