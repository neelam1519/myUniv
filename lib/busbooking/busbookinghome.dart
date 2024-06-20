import 'dart:convert';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/apis/busbookinggsheet.dart';
import 'package:findany_flutter/busbooking/history.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BusBookingHome extends StatefulWidget {
  @override
  _BusBookingHomeState createState() => _BusBookingHomeState();
}

class _BusBookingHomeState extends State<BusBookingHome> {
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
  String busID="";
  int _waitingListSeats = 0;
  int _availableSeats = 0;
  String? _announcementText;  // State variable to store the fetched text

  Map<String, dynamic>? detailsData = {};
  Map<String, dynamic>? placesData = {};
  Map<String, Map<String,List<String>>> dateToTimingsMap = {};

  DocumentReference placesDoc = FirebaseFirestore.instance.doc("busbooking/places");
  DocumentReference detailsDoc = FirebaseFirestore.instance.doc("busbooking/Details");

  final TextEditingController _costController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  String _mobileNumber = "";

  List<Map<String, String?>> _people = []; // List to store people details

  // Razorpay
  Razorpay razorpay = Razorpay();
  String apiUrl = 'https://api.razorpay.com/v1/orders';
  static const _razorpayKey = 'rzp_live_kYGlb6Srm9dDRe';
  static const _apiSecret = 'GPRg9ri7zy4r7QeRe9lT2xUx';

  @override
  void initState() {
    super.initState();
    _fetchFromPlaces();
    initializeRazorpay();
    _fetchAnnouncementText();
    utils.sendSMS('Testing the SMS', "8501070702");
  }

  Future<void> listen(String busID) async {
    loadingDialog.showDefaultLoading("Getting Seats Availability...");
    final DatabaseReference databaseReference = _database.ref('BusBookingTickets/$busID');

    databaseReference.onValue.listen((event) {
      final dataSnapshot = event.snapshot;
      if (dataSnapshot.exists) {
        _availableSeats = dataSnapshot.child('Available').value as int;
        _waitingListSeats = dataSnapshot.child('WaitingList').value as int;
        setState(() {
          _availableSeats;
          _waitingListSeats;
        });
        print('Available Seats: $_availableSeats');
        print('Waiting List: $_waitingListSeats');
      } else {
        print('No data available for busID: $busID');
      }
    });

    _availableSeats = await realTimeDatabase.getCurrentValue('BusBookingTickets/$busID/Available') ?? 0;
    _waitingListSeats = await realTimeDatabase.getCurrentValue('BusBookingTickets/$busID/WaitingList') ?? 0;

    setState(() {

    });

    loadingDialog.dismiss();
  }

  Future<void> _fetchAnnouncementText() async {
    final DatabaseReference announcementRef = _database.ref('BusBookingTickets/Announcements');
    announcementRef.onValue.listen((event) {
      final DataSnapshot snapshot = event.snapshot;
      if (snapshot.exists) {
        setState(() {
          _announcementText = snapshot.value as String?;
        });
      } else {
        setState(() {
          _announcementText = null;
        });
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
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode("$_razorpayKey:$_apiSecret"))}',
        },
        body: jsonEncode(<String, dynamic>{
          'amount': amount * 100,
          'currency': 'INR',
          'receipt': 'order_receipt_${DateTime.now().millisecondsSinceEpoch}',
          'payment_capture': 1, // Auto capture payment
        }),
      );

      if (response.statusCode == 200) {
        print('Got response code as 200');
        final responseData = jsonDecode(response.body);
        return responseData['id']; // Return the order ID
      } else {
        print('Failed to create order: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  void startPayment(int amount, String number, String email) async {
    if(!await utils.checkInternetConnection()){
      utils.showToastMessage('Connect to the Internet', context);
      return;
    }
    loadingDialog.showDefaultLoading('Redirecting to Payment Page');
    final orderId = await createOrder(amount); // Call to createOrder
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
      // Handle error in creating order
      print('Order is Null');
    }
  }

  Future<void> handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('razorpay successful ${response.paymentId}');
    await updateTickets(_people.length,response);
  }

  void handlePaymentError(PaymentFailureResponse response) {
    print('razorpay unsuccessful: ${response.message}');
    utils.showToastMessage('Payment unsuccessful', context);
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    print('razorpay External wallet ${response.walletName}');
  }

  Future<void> updateTickets(int peopleCount,PaymentSuccessResponse response) async {
    final DatabaseReference ticketRef = _database.ref('BusBookingTickets/$busID');
    String availableTickets = 'BusBookingTickets/$busID/Available';
    String waitingListTickets = 'BusBookingTickets/$busID/WaitingList';

    int currentTickets = (await realTimeDatabase.getCurrentValue(availableTickets) as int?) ?? 0;
    int currentWaitingList = (await realTimeDatabase.getCurrentValue(waitingListTickets) as int?) ?? 0;
    int waitingListCount = 0;
    int confirmTicketCount = 0;

    if (currentTickets <= 0) {
      // If there are no available tickets, add the people count to the waiting list
      currentWaitingList += peopleCount;
      await ticketRef.child('WaitingList').set(currentWaitingList);
      waitingListCount = peopleCount;
      print('All tickets are sold out. Added $peopleCount people to the waiting list.');
    } else if (peopleCount <= currentTickets) {
      // If available tickets are enough to cover people count, book the tickets
      currentTickets -= peopleCount;
      await ticketRef.child('Available').set(currentTickets);
      confirmTicketCount= peopleCount;
      print('Booked $peopleCount tickets. Remaining tickets: $currentTickets');
    } else {
      // If available tickets are less than people count, book the available tickets and add the rest to the waiting list
      int bookedTickets = currentTickets;
      int waitingListAddition = peopleCount - currentTickets;
      currentTickets = 0;
      currentWaitingList += waitingListAddition;

      await ticketRef.child('Available').set(currentTickets);
      await ticketRef.child('WaitingList').set(currentWaitingList);

      waitingListCount = waitingListAddition;
      confirmTicketCount = bookedTickets;

      print('Booked $bookedTickets tickets. Added $waitingListAddition people to the waiting list.');
    }

    await uploadData(response,confirmTicketCount,waitingListCount);

  }

  Future<void> uploadData(PaymentSuccessResponse response,int confirmTickets, int waitingListTickets) async {
    loadingDialog.showDefaultLoading('Booking Ticket...');
    print('Response: ${response.data}');

    String? email = await utils.getCurrentUserEmail();
    String regNo = utils.removeEmailDomain(email!);

    int? bookingID= await realTimeDatabase.incrementValue("BusBookingTickets/TicketID");

    List<dynamic> data = [
      regNo,
      _mobileNumber,
      email,
      _selectedFrom.toString(),
      _selectedTo.toString(),
      _selectedDate.toString(),
      _selectedTiming.toString(),
      _totalCostController.text,
      response.paymentId ?? "",
      bookingID,
      "$confirmTickets - $waitingListTickets",
      _people.toString()
    ];

    busBookingGSheet.updateCell(data);

    Map<String, dynamic> busBookingData = {
      'REGISTRATION NUMBER': regNo,
      'MOBILE NUMBER': _mobileNumber,
      'FROM': _selectedFrom,
      'TO': _selectedTo,
      'DATE': _selectedDate,
      'TIMINGS': _selectedTiming,
      'TOTAL COST': _totalCostController.text,
      'PAYMENT ID': response.paymentId,
      'PEOPLE LIST': _people,
      'TICKET COUNT': _people.length,
      'CONFORM TICKETS':confirmTickets,
      'WAITING LIST TICKETS': waitingListTickets,
      'BOOKING ID' : bookingID
    };

    DocumentReference historyRef = FirebaseFirestore.instance.doc("UserDetails/${await utils.getCurrentUserUID()}/BusBooking/BookedTickets");

    DocumentReference busDetailsRef = FirebaseFirestore.instance.doc('/busbooking/BookingIDs/$busID/$bookingID');
    await fireStoreService.uploadMapDataToFirestore(busBookingData, busDetailsRef);
    Map<String,dynamic> historyData = {bookingID.toString():busDetailsRef};
    await fireStoreService.uploadMapDataToFirestore(historyData, historyRef);
    utils.showToastMessage('Ticket is booked check the history', context);
    
    DocumentReference tokenRef = FirebaseFirestore.instance.doc('AdminDetails/BusBooking');
    List<String> tokens = await utils.getSpecificTokens(tokenRef);

    notificationService.sendNotification(tokens, "Bus Booking", 'Bus is booked with the ID: $bookingID', {});

    String? token = await utils.getToken();

    notificationService.sendNotification([token], "Bus Booking", 'Your bus is booked with the ID $bookingID you can check your booking details in the history', {});


    Navigator.pop(context);
    loadingDialog.dismiss();
  }

  Future<void> _fetchFromPlaces() async {
    loadingDialog.showDefaultLoading("Getting data...");
    try {
      placesData = await fireStoreService.getDocumentDetails(placesDoc);

      if (placesData != null && placesData!.isNotEmpty) {
        setState(() {
          _fromPlaces = List<String>.from(placesData!['from'] ?? []);
          _toPlaces = List<String>.from(placesData!['to'] ?? []);
          _selectedFrom = _fromPlaces.isNotEmpty ? _fromPlaces.first : null;
          _selectedTo = _toPlaces.isNotEmpty ? _toPlaces.first : null;
        });

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

  Future<void> _fetchDetails(String fromPlace, String toPlace) async {
    // loadingDialog.showDefaultLoading("Getting details... $fromPlace  $toPlace");
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
        final timeFormat = DateFormat('HH:mm');

        datesData.forEach((id, timestamp) {
          DateTime dateTime = (timestamp as Timestamp).toDate();
          String date = dateFormat.format(dateTime);
          String time = timeFormat.format(dateTime);
          availableDates.add(date);

          if (!dateToTimingsMap.containsKey(date)) {
            dateToTimingsMap[date] = {};
          }

          if (!dateToTimingsMap[date]!.containsKey(id)) {
            dateToTimingsMap[date]![id] = [];
          }

          dateToTimingsMap[date]![id]!.add(time); // Store time in the list for each ID

        });

        print("Dates Data: $dateToTimingsMap");
        setState(() {
          _availableDates = availableDates.toList();
          _selectedDateFormatted = _availableDates.isNotEmpty ? _availableDates.first : null;
          _selectedDate = _selectedDateFormatted != null ? dateFormat.parse(_selectedDateFormatted!) : null;

          _updateTimingsForSelectedDate();

          _travelCost = double.tryParse(details['Cost'].toString()) ?? 0;
          _selectedTiming = _timings.isNotEmpty ? _timings.first : null;
          _costController.text = _travelCost != null ? '₹${_travelCost!.toStringAsFixed(2)}' : 'N/A';
          _updateTotalCost();
        });
      } else {
        print('No Data in fetchDetails');
        setState(() {
          _availableDates = [];
          _timings = [];
          _travelCost = null;
          _costController.text = 'N/A';
          _updateTotalCost();
        });
      }
    } catch (e) {
      print("Fetch Details: $e");
    } finally {
      loadingDialog.dismiss();
    }
  }

  void _updateTimingsForSelectedDate() {
    final dateFormat = DateFormat('dd-MM-yyyy');

    if (_selectedDate != null) {
      String selectedDateString = dateFormat.format(_selectedDate!);
      setState(() {
        if (dateToTimingsMap.containsKey(selectedDateString)) {
          _timings = dateToTimingsMap[selectedDateString]!.values.expand((timings) => timings).toList();
        } else {
          _timings = [];
        }
        _selectedTiming = _timings.isNotEmpty ? _timings.first : null;
        _updateBusID();
      });
    }
  }

  void _updateTotalCost() {
    double totalCost = (_travelCost ?? 0) * _people.length;
    _totalCostController.text = '₹${totalCost.toStringAsFixed(2)}';
  }

  void _addPerson() {
    setState(() {
      _people.add({'name': null, 'gender': null});
      _updateTotalCost();
    });
  }

  void _removePerson(int index) {
    setState(() {
      _people.removeAt(index);
      _updateTotalCost();
    });
  }

  void _searchBuses() async {
    if (_selectedFrom == null || _selectedTo == null || _selectedDate == null || _selectedTiming == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    print('People: $_people');

    for (var person in _people) {
      if (person['name'] == null || person['gender'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill the Pesons details')),
        );
        return;
      }
    }

    if (_people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add the Pesons details')),
      );
      return;
    }


    if (!utils.isValidMobileNumber(_mobileNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter Valid Mobile Number")),
      );
      return;
    }

    String? email = await utils.getCurrentUserEmail();
    String amt = _totalCostController.text.replaceAll("₹", "");
    double amount = double.parse(amt);
    int cost = amount.round();
    startPayment(cost, _mobileNumber, email ?? "Email Not Found");
    print('Details $_people $_selectedFrom  $_selectedTo $_selectedDate  $_selectedTiming');
  }

  void _updateBusID() {
    final dateFormat = DateFormat('dd-MM-yyyy');

    if (_selectedDate != null && _selectedTiming != null) {
      String selectedDateString = dateFormat.format(_selectedDate!);
      if (dateToTimingsMap.containsKey(selectedDateString)) {
        Map<String, List<String>> timingsMap = dateToTimingsMap[selectedDateString]!;
        for (String id in timingsMap.keys) {
          if (timingsMap[id]!.contains(_selectedTiming)) {
            setState(() {
              busID = id;
              listen(busID);
              print('Updated BusID: $busID');
            });
            return;
          }
        }
      }
    }
    setState(() {
      busID = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Booking'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BusBookedHistory()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              if (_announcementText != null && _announcementText!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: Text(
                    _announcementText!,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedFrom,
                decoration: InputDecoration(
                  labelText: 'From',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFrom = newValue;
                    _availableDates = [];
                    _timings = [];
                    _travelCost = null;
                    _costController.text = 'N/A';
                  });
                  if (newValue != null && _selectedTo != null) {
                    _fetchDetails(newValue, _selectedTo!);
                  }
                },
                items: _fromPlaces.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedTo,
                decoration: InputDecoration(
                  labelText: 'To',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTo = newValue;
                    _availableDates = [];
                    _timings = [];
                    _travelCost = null;
                    _costController.text = 'N/A';
                  });
                  if (newValue != null && _selectedFrom != null) {
                    _fetchDetails(_selectedFrom!, newValue);
                  }
                },
                items: _toPlaces.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedDateFormatted,
                decoration: InputDecoration(
                  labelText: 'Select Date',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDateFormatted = newValue;
                    _selectedDate = DateFormat('dd-MM-yyyy').parse(newValue!);
                    _updateTimingsForSelectedDate();
                  });
                },
                items: _availableDates.map<DropdownMenuItem<String>>((String date) {
                  return DropdownMenuItem<String>(
                    value: date,
                    child: Text(date),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedTiming,
                decoration: InputDecoration(
                  labelText: 'Timing',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTiming = newValue;
                    _updateBusID();
                  });
                },
                items: _timings.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _mobileNumber = value;
                  });
                },
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16.0),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _people.length,
                itemBuilder: (context, index) {
                  var person = _people[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            decoration: InputDecoration(
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
                        SizedBox(width: 8.0),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: person['gender'],
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                person['gender'] = newValue;
                              });
                            },
                            items: ['M', 'F', 'O'].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removePerson(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addPerson,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 16),
                ),
                child: Text('Add Person'),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _costController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Cost per Person',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _totalCostController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Total Cost',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                'Available Seats: $_availableSeats',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Waiting List Seats: $_waitingListSeats',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16.0),
              Text(
                "If we receive a significant number of bookings on the waiting list, an additional bus will be arranged",
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 16.0),
              Text(
                'Note: 95% refund on unconfirmed tickets.',
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _searchBuses,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 16),
                ),
                child: Text('Book Bus'),
              ),
              SizedBox(height: 16.0),
              Text(
                'Any timing adjustments contact us through  \nEmail: neelammsr@gmail.com  \nMobile Number: 8501070702 or 7207010295',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    loadingDialog.dismiss();
    super.dispose();
  }

}
