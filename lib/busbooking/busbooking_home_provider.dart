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
  Map<String, List<double>> _travelCosts = {};
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


  List<String> get fromPlaces => _fromPlaces;

  List<String> get toPlaces => _toPlaces;

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
    // double totalCost = (_travelCost ?? 0) * _people.length;
    // _totalCostController.text = '₹${totalCost.toStringAsFixed(2)}';
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

  Future<void> fetchBusDetails() async {
    try {
      // Clear previous data
      _fromPlaces.clear();
      _toPlaces.clear();
      _availableDates.clear();
      _timings.clear();

      // Fetch all bus documents from the Firestore collection
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('buses').get();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Extract and add data to respective lists if not already present
        if (data.containsKey('from') && !_fromPlaces.contains(data['from'])) {
          _fromPlaces.add(data['from']);
        }
        if (data.containsKey('to') && !_toPlaces.contains(data['to'])) {
          _toPlaces.add(data['to']);
        }
        if (data.containsKey('date') && !_availableDates.contains(data['date'])) {
          _availableDates.add(data['date']);
        }
        if (data.containsKey('time') && !_timings.contains(data['time'])) {
          _timings.add(data['time']);
        }

        // Extract and store travel cost for specific routes
        if (data.containsKey('from') && data.containsKey('to') && data.containsKey('price')) {
          if (_travelCosts.containsKey(doc.id)) {
            _travelCosts[doc.id]!.add(data['price']);
          } else {
            _travelCosts[doc.id] = [data['price']];
          }
        }
      }

      // Sort lists for better usability
      _fromPlaces.sort();
      _toPlaces.sort();
      _availableDates.sort();
      _timings.sort();

      // Debug or process travel costs
      _travelCosts.forEach((route, prices) {
        debugPrint("Route: $route, Prices: ${prices.join(", ")}");
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching bus details: $e');
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