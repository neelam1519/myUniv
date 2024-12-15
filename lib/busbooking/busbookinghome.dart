// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_linkify/flutter_linkify.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:findany_flutter/Firebase/firestore.dart';
// import 'package:findany_flutter/Firebase/realtimedatabase.dart';
// import 'package:findany_flutter/apis/busbookinggsheet.dart';
// import 'package:findany_flutter/busbooking/history.dart';
// import 'package:findany_flutter/services/sendnotification.dart';
// import 'package:findany_flutter/utils/LoadingDialog.dart';
// import 'package:findany_flutter/utils/utils.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class BusBookingHome extends StatefulWidget {
//   const BusBookingHome({super.key});
//
//   @override
//   State<BusBookingHome> createState() => _BusBookingHomeState();
// }
//
// class _BusBookingHomeState extends State<BusBookingHome> {
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
//   @override
//   void initState() {
//     super.initState();
//     _fetchFromPlaces();
//     initializeRazorpay();
//     _fetchAnnouncementText();
//   }
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
//         setState(() {
//           _availableSeats;
//           _waitingListSeats;
//         });
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
//
//     setState(() {});
//
//     loadingDialog.dismiss();
//   }
//
//   Future<void> _fetchAnnouncementText() async {
//     final DatabaseReference announcementRef = _database.ref('BusBookingTickets/Announcements');
//     announcementRef.onValue.listen((event) {
//       final DataSnapshot snapshot = event.snapshot;
//       if (snapshot.exists) {
//         setState(() {
//           _announcementText = snapshot.value as String?;
//         });
//       } else {
//         setState(() {
//           _announcementText = null;
//         });
//       }
//     });
//
//     final DatabaseReference messageText = _database.ref('BusBookingTickets/message');
//     messageText.onValue.listen((event) {
//       final DataSnapshot snapshot = event.snapshot;
//       if (snapshot.exists) {
//         setState(() {
//           message = snapshot.value as String?;
//         });
//       } else {
//         setState(() {
//           message = null;
//         });
//       }
//     });
//
//     final DatabaseReference contactText = _database.ref('BusBookingTickets/contact');
//     contactText.onValue.listen((event) {
//       final DataSnapshot snapshot = event.snapshot;
//       if (snapshot.exists) {
//         setState(() {
//           contactus = snapshot.value as String?;
//         });
//       } else {
//         setState(() {
//           contactus = null;
//         });
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
//
//     Navigator.pop(context);
//     loadingDialog.dismiss();
//   }
//
//   Future<void> _fetchFromPlaces() async {
//     loadingDialog.showDefaultLoading("Getting data...");
//     try {
//       placesData = await fireStoreService.getDocumentDetails(placesDoc);
//
//       if (placesData != null && placesData!.isNotEmpty) {
//         setState(() {
//           _fromPlaces = List<String>.from(placesData!['from'] ?? []);
//           _toPlaces = List<String>.from(placesData!['to'] ?? []);
//           _selectedFrom = _fromPlaces.isNotEmpty ? _fromPlaces.first : null;
//           _selectedTo = _toPlaces.isNotEmpty ? _toPlaces.first : null;
//         });
//
//         if (_selectedFrom != null && _selectedTo != null) {
//           _fetchDetails(_selectedFrom!, _selectedTo!);
//         }
//       } else {
//         print('Empty Data Found');
//       }
//     } catch (e) {
//       print(e);
//     } finally {
//       loadingDialog.dismiss();
//     }
//   }
//
//   Future<void> _fetchDetails(String fromPlace, String toPlace) async {
//     try {
//       Map<String, dynamic>? detailsData = await FireStoreService().getDocumentDetails(detailsDoc);
//       print('Details Data: $detailsData');
//       if (detailsData != null && detailsData.containsKey(fromPlace)) {
//         Map<String, dynamic> details = detailsData[fromPlace][toPlace];
//
//         print("Fetched Details: $details");
//
//         Map<String, dynamic> datesData = details['Dates'];
//
//         Set<String> availableDates = {};
//         dateToTimingsMap.clear();
//
//         final dateFormat = DateFormat('dd-MM-yyyy');
//
//         datesData.forEach((id, timestamp) {
//           DateTime dateTime = (timestamp as Timestamp).toDate();
//           String date = dateFormat.format(dateTime);
//           String time = timeFormat.format(dateTime); // Changed to use the new time format
//           availableDates.add(date);
//
//           if (!dateToTimingsMap.containsKey(date)) {
//             dateToTimingsMap[date] = {};
//           }
//
//           if (!dateToTimingsMap[date]!.containsKey(id)) {
//             dateToTimingsMap[date]![id] = [];
//           }
//
//           dateToTimingsMap[date]![id]!.add(time);
//         });
//
//         // Sort dates
//         setState(() {
//           _availableDates = availableDates.toList()..sort((a, b) => dateFormat.parse(a).compareTo(dateFormat.parse(b)));
//           _selectedDateFormatted = _availableDates.isNotEmpty ? _availableDates.first : null;
//           _selectedDate = _selectedDateFormatted != null ? dateFormat.parse(_selectedDateFormatted!) : null;
//
//           _updateTimingsForSelectedDate();
//
//           _travelCost = double.tryParse(details['Cost'].toString()) ?? 0;
//           _selectedTiming = _timings.isNotEmpty ? _timings.first : null;
//           _costController.text = _travelCost != null ? '₹${_travelCost!.toStringAsFixed(2)}' : 'N/A';
//           _updateTotalCost();
//         });
//       } else {
//         print('No Data in fetchDetails');
//         setState(() {
//           _availableDates = [];
//           _timings = [];
//           _travelCost = null;
//           _costController.text = 'N/A';
//           _updateTotalCost();
//         });
//       }
//     } catch (e) {
//       print("Fetch Details: $e");
//     } finally {
//       loadingDialog.dismiss();
//     }
//   }
//
//   void _updateTimingsForSelectedDate() {
//     final dateFormat = DateFormat('dd-MM-yyyy');
//
//     if (_selectedDate != null) {
//       String selectedDateString = dateFormat.format(_selectedDate!);
//       setState(() {
//         if (dateToTimingsMap.containsKey(selectedDateString)) {
//           _timings = dateToTimingsMap[selectedDateString]!.values.expand((timings) => timings).toList();
//           // Sort timings
//           _timings.sort((a, b) => timeFormat.parse(a).compareTo(timeFormat.parse(b)));
//         } else {
//           _timings = [];
//         }
//         _selectedTiming = _timings.isNotEmpty ? _timings.first : null;
//         _updateBusID();
//       });
//     }
//   }
//
//   void _updateTotalCost() {
//     double totalCost = (_travelCost ?? 0) * _people.length;
//     _totalCostController.text = '₹${totalCost.toStringAsFixed(2)}';
//   }
//
//   void _addPerson() {
//     setState(() {
//       _people.add({'name': null, 'gender': null});
//       _updateTotalCost();
//     });
//   }
//
//   void _removePerson(int index) {
//     setState(() {
//       _people.removeAt(index);
//       _updateTotalCost();
//     });
//   }
//
//   void _searchBuses() async {
//     if (_selectedFrom == null || _selectedTo == null || _selectedDate == null || _selectedTiming == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill in all fields')),
//       );
//       return;
//     }
//     print('People: $_people');
//
//     for (var person in _people) {
//       if (person['name'] == null || person['gender'] == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Please fill the Persons details')),
//         );
//         return;
//       }
//     }
//
//     if (_people.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please add the Persons details')),
//       );
//       return;
//     }
//
//     if (!utils.isValidMobileNumber(_mobileNumber)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Enter Valid Mobile Number")),
//       );
//       return;
//     }
//
//     String? email = await utils.getCurrentUserEmail();
//     String amt = _totalCostController.text.replaceAll("₹", "");
//     double amount = double.parse(amt);
//     int cost = amount.round();
//     startPayment(cost, _mobileNumber, email ?? "Email Not Found");
//     print('Details $_people $_selectedFrom  $_selectedTo $_selectedDate  $_selectedTiming');
//   }
//
//   void _updateBusID() {
//     final dateFormat = DateFormat('dd-MM-yyyy');
//
//     if (_selectedDate != null && _selectedTiming != null) {
//       String selectedDateString = dateFormat.format(_selectedDate!);
//       if (dateToTimingsMap.containsKey(selectedDateString)) {
//         Map<String, List<String>> timingsMap = dateToTimingsMap[selectedDateString]!;
//         for (String id in timingsMap.keys) {
//           if (timingsMap[id]!.contains(_selectedTiming)) {
//             setState(() {
//               busID = id;
//               listen(busID);
//               print('Updated BusID: $busID');
//             });
//             return;
//           }
//         }
//       }
//     }
//     setState(() {
//       busID = "";
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bus Booking'),
//         backgroundColor: Colors.green,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.history, color: Colors.white),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => BusBookedHistory()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             children: <Widget>[
//               if (_announcementText != null && _announcementText!.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
//                   child: Linkify(
//                     text: _announcementText!,
//                     style: const TextStyle(
//                       fontSize: 16.0,
//                       color: Colors.green,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     linkStyle: const TextStyle(
//                       color: Colors.blue,
//                       decoration: TextDecoration.underline,
//                     ),
//                     onOpen: (link) async {
//                       if (await canLaunch(link.url)) {
//                         await launch(link.url);
//                       } else {
//                         throw 'Could not launch ${link.url}';
//                       }
//                     },
//                   ),
//                 ),
//               const SizedBox(height: 16.0),
//               DropdownButtonFormField<String>(
//                 value: _selectedFrom,
//                 decoration: const InputDecoration(
//                   labelText: 'From',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedFrom = newValue;
//                     _availableDates = [];
//                     _timings = [];
//                     _travelCost = null;
//                     _costController.text = 'N/A';
//                   });
//                   if (newValue != null && _selectedTo != null) {
//                     _fetchDetails(newValue, _selectedTo!);
//                   }
//                 },
//                 items: _fromPlaces.map<DropdownMenuItem<String>>((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 16.0),
//               DropdownButtonFormField<String>(
//                 value: _selectedTo,
//                 decoration: const InputDecoration(
//                   labelText: 'To',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedTo = newValue;
//                     _availableDates = [];
//                     _timings = [];
//                     _travelCost = null;
//                     _costController.text = 'N/A';
//                   });
//                   if (newValue != null && _selectedFrom != null) {
//                     _fetchDetails(_selectedFrom!, newValue);
//                   }
//                 },
//                 items: _toPlaces.map<DropdownMenuItem<String>>((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 16.0),
//               DropdownButtonFormField<String>(
//                 value: _selectedDateFormatted,
//                 decoration: const InputDecoration(
//                   labelText: 'Select Date',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedDateFormatted = newValue;
//                     _selectedDate = DateFormat('dd-MM-yyyy').parse(newValue!);
//                     _updateTimingsForSelectedDate();
//                   });
//                 },
//                 items: _availableDates.map<DropdownMenuItem<String>>((String date) {
//                   return DropdownMenuItem<String>(
//                     value: date,
//                     child: Text(date),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 16.0),
//               DropdownButtonFormField<String>(
//                 value: _selectedTiming,
//                 decoration: const InputDecoration(
//                   labelText: 'Timing',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedTiming = newValue;
//                     _updateBusID();
//                   });
//                 },
//                 items: _timings.map<DropdownMenuItem<String>>((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 16.0),
//               TextFormField(
//                 decoration: const InputDecoration(
//                   labelText: 'Mobile Number*',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     _mobileNumber = value;
//                   });
//                 },
//                 keyboardType: TextInputType.phone,
//               ),
//               const SizedBox(height: 16.0),
//               TextFormField(
//                 decoration: const InputDecoration(
//                   labelText: 'Train No/Bus drop time',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     trainNo = value;
//                   });
//                 },
//               ),
//               const SizedBox(height: 16.0),
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: _people.length,
//                 itemBuilder: (context, index) {
//                   var person = _people[index];
//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: 8.0),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           flex: 3,
//                           child: TextFormField(
//                             decoration: const InputDecoration(
//                               labelText: 'Name',
//                               border: OutlineInputBorder(),
//                             ),
//                             onChanged: (value) {
//                               setState(() {
//                                 person['name'] = value;
//                               });
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 8.0),
//                         Expanded(
//                           flex: 1,
//                           child: DropdownButtonFormField<String>(
//                             value: person['gender'],
//                             decoration: const InputDecoration(
//                               labelText: 'Gender',
//                               border: OutlineInputBorder(),
//                             ),
//                             onChanged: (String? newValue) {
//                               setState(() {
//                                 person['gender'] = newValue;
//                               });
//                             },
//                             items: ['M', 'F'].map<DropdownMenuItem<String>>((String value) {
//                               return DropdownMenuItem<String>(
//                                 value: value,
//                                 child: Text(value),
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.red),
//                           onPressed: () => _removePerson(index),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 16.0),
//               ElevatedButton(
//                 onPressed: _addPerson,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//                   textStyle: const TextStyle(fontSize: 16),
//                 ),
//                 child: const Text('Add Person'),
//               ),
//               const SizedBox(height: 16.0),
//               TextFormField(
//                 controller: _costController,
//                 readOnly: true,
//                 decoration: const InputDecoration(
//                   labelText: 'Cost per Person',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16.0),
//               TextFormField(
//                 controller: _totalCostController,
//                 readOnly: true,
//                 decoration: const InputDecoration(
//                   labelText: 'Total Cost',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Available Seats: $_availableSeats',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                   if (_waitingListSeats > 0)
//                     Text(
//                       'Waiting List Seats: $_waitingListSeats',
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   const SizedBox(height: 16.0),
//                   if (message?.isNotEmpty ?? false)
//                     Text(
//                       message!,
//                       style: const TextStyle(color: Colors.red),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 16.0),
//               ElevatedButton(
//                 onPressed: _searchBuses,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//                   textStyle: const TextStyle(fontSize: 16),
//                 ),
//                 child: const Text('Book Ticket'),
//               ),
//               const SizedBox(height: 16.0),
//               Text(
//                 contactus!,
//                 style: const TextStyle(color: Colors.red),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     loadingDialog.dismiss();
//     super.dispose();
//   }
// }
//
//

import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:findany_flutter/busbooking/history.dart';
import 'package:url_launcher/url_launcher.dart';

import 'busbooking_home_provider.dart';

class BusBookingHome extends StatefulWidget {
  const BusBookingHome({super.key});

  @override
  State<BusBookingHome> createState() => _BusBookingHomeState();
}

class _BusBookingHomeState extends State<BusBookingHome> {
  BusBookingHomeProvider? busBookingHomeProvider;

  @override
  void initState() {
    super.initState();
    final busBookingHomeProvider = Provider.of<BusBookingHomeProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      busBookingHomeProvider
        ..fetchFromPlaces()
        ..initializeRazorpay()
        ..fetchAnnouncementText();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Bus Booking'),
          backgroundColor: Colors.green,
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BusBookedHistory()),
                );
              },
            ),
          ],
        ),
        body: Consumer<BusBookingHomeProvider>(
          builder: (context, busHomeProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    if (busHomeProvider.announcementText != null && busHomeProvider.announcementText!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
                        child: Linkify(
                          text: busHomeProvider.announcementText!,
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          linkStyle: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          onOpen: (link) async {
                            if (await canLaunch(link.url)) {
                              await launch(link.url);
                            } else {
                              throw 'Could not launch ${link.url}';
                            }
                          },
                        ),
                      ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: busHomeProvider.selectedFrom,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String? newValue) async{
                        busHomeProvider.selectedFrom = newValue;
                        busHomeProvider.availableDates = [];
                        busHomeProvider.timings = [];
                        busHomeProvider.travelCost = null;
                        busHomeProvider.costController.text = 'N/A';
                        if (newValue != null && busHomeProvider.selectedTo != null) {
                          await busHomeProvider.fetchDetails(newValue, busHomeProvider.selectedTo!);
                        }
                      },
                      items: busHomeProvider.fromPlaces.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: busHomeProvider.selectedTo,
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String? newValue) async{
                        setState(() {
                          busHomeProvider.selectedTo = newValue;
                          busHomeProvider.availableDates = [];
                          busHomeProvider.timings = [];
                          busHomeProvider.travelCost = null;
                          busHomeProvider.costController.text = 'N/A';
                        });
                        if (newValue != null && busHomeProvider.selectedFrom != null) {
                          await busHomeProvider.fetchDetails(busHomeProvider.selectedFrom!, newValue);
                        }
                      },
                      items: busHomeProvider.toPlaces.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: busHomeProvider.selectedDateFormatted,
                      decoration: const InputDecoration(
                        labelText: 'Select Date',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String? newValue) {
                        setState(() async{
                          busHomeProvider.selectedDateFormatted = newValue;
                          busHomeProvider.selectedDate = DateFormat('dd-MM-yyyy').parse(newValue!);
                          await busHomeProvider.updateTimingsForSelectedDate();
                        });
                      },
                      items: busHomeProvider.availableDates.map<DropdownMenuItem<String>>((String date) {
                        return DropdownMenuItem<String>(
                          value: date,
                          child: Text(date),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: busHomeProvider.selectedTiming,
                      decoration: const InputDecoration(
                        labelText: 'Timing',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String? newValue){
                        setState(() async {
                          busHomeProvider.selectedTiming = newValue;
                          await busHomeProvider.updateBusID();
                        });
                      },
                      items: busHomeProvider.timings.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number*',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          busHomeProvider.mobileNumber = value;
                        });
                      },
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Train No/Bus drop time',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          busHomeProvider.trainNo = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: busHomeProvider.people.length,
                      itemBuilder: (context, index) {
                        var person = busHomeProvider.people[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      person['name'] = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: person['gender'],
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      person['gender'] = newValue;
                                    });
                                  },
                                  items: ['M', 'F'].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async{
                                  await busHomeProvider.removePerson(index);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: busHomeProvider.addPerson,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Add Person'),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: busHomeProvider.costController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Cost per Person',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: busHomeProvider.totalCostController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Total Cost',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Seats: ${busHomeProvider.availableSeats}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (busHomeProvider.waitingListSeats > 0)
                          Text(
                            'Waiting List Seats: ${busHomeProvider.waitingListSeats}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        const SizedBox(height: 16.0),
                        if (busHomeProvider.message?.isNotEmpty ?? false)
                          Text(
                            busHomeProvider.message!,
                            style: const TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () async{
                        await busHomeProvider.searchBuses(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Book Ticket'),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      busHomeProvider.contactus!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          },
        ));
  }

  @override
  void dispose() {
    busBookingHomeProvider?.loadingDialog.dismiss();
    super.dispose();
  }
}
