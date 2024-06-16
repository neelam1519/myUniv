import 'dart:convert';

import 'package:findany_flutter/apis/busbookinggsheet.dart';
import 'package:findany_flutter/utils/utils.dart';
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

  Utils utils = Utils();

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
  List<DocumentSnapshot> _availableBuses = [];
  String busID="";

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
    utils.showToastMessage('Payment Sucessfull', context);
    await uploadData(response);
  }

  void handlePaymentError(PaymentFailureResponse response) {
    print('razorpay unsuccessful: ${response.message}');
    utils.showToastMessage('Payment unsuccessful', context);
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    print('razorpay External wallet ${response.walletName}');
  }

  Future<void> uploadData(PaymentSuccessResponse response) async {
    loadingDialog.showDefaultLoading('Uploading the data');
    print('Response: ${response.data}');

    String? email = await utils.getCurrentUserEmail();
    String regNo = utils.removeEmailDomain(email!);

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
      _people.length,
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
      'TOTAL COST': _totalCostController,
      'PAYMENT ID': response.paymentId,
      'PEOPLE LIST': _people
    };

    DocumentReference busDetailsRef = FirebaseFirestore.instance.doc('/BusBookingDetails/${utils.getTodayDate().replaceAll('/', '-')}');
    await fireStoreService.uploadMapDataToFirestore(busBookingData, busDetailsRef);
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
        _updateBusID(); // Call the method to update the bus ID
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

    if (_people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the Pesons details')),
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
              print('Updated BusID: $busID');
            });
            return;
          }
        }
      }
    }
    setState(() {
      busID = ""; // Reset if no matching ID is found
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Booking'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
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
                          icon: Icon(Icons.delete),
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
              ElevatedButton(
                onPressed: _searchBuses,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 16),
                ),
                child: Text('Book bus'),
              ),
              SizedBox(height: 16.0),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _availableBuses.length,
                itemBuilder: (context, index) {
                  var bus = _availableBuses[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text('Bus: ${bus['busNumber']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Departure: ${bus['departureTime']}'),
                          Text('From: ${bus['from']} To: ${bus['to']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
