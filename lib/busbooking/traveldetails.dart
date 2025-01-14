import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/busbooking/paymentstatus.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';

import '../apis/razorpay.dart';


class TravelDetailsPage extends StatefulWidget {
  final Map<String, dynamic> busDetails;

  const TravelDetailsPage({Key? key, required this.busDetails}) : super(key: key);

  @override
  _TravelDetailsPageState createState() => _TravelDetailsPageState();
}

class _TravelDetailsPageState extends State<TravelDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contactController = TextEditingController();
  Utils utils = Utils();
  final List<Map<String, dynamic>> _passengers = [
    {'name': '', 'gender': 'M'}
  ];

  int availableSeats = 0;

  int get ticketPrice => widget.busDetails['price'].round() ?? 0;

  int get totalCost => _passengers.length * ticketPrice;

  @override
  void initState() {
    super.initState();
    availableSeats = widget.busDetails["availableSeats"];

    _listenToBusSeatUpdates();
  }

  // Listen for updates in the Firestore document to track seat availability
  void _listenToBusSeatUpdates() {
    print("bus  listen: ${widget.busDetails}");
    FirebaseFirestore.instance
        .collection('buses')
        .doc(widget.busDetails['busNumber'].toString())  // assuming you have a busId field
        .snapshots()
        .listen((documentSnapshot) {
      if (documentSnapshot.exists) {
        final updatedBusData = documentSnapshot.data()!;
        print("updated bus details $updatedBusData");
        setState(() {
          availableSeats = updatedBusData["availableSeats"];
        });
      }
    });

  }

  void _addPassenger() {
    if (_passengers.last['name'].isNotEmpty && availableSeats > 0) {
      setState(() {
        _passengers.add({'name': '', 'gender': 'M'});
      });
    } else if (availableSeats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more seats available!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the name of the current passenger!')),
      );
    }
  }

  void _removePassenger(int index) {
    setState(() {
      _passengers.removeAt(index);
    });
  }

  Future<void> _submitBooking() async {
    if (_formKey.currentState?.validate() ?? false) {
      String? email = await utils.getCurrentUserEmail();
      String mobileNumber = _contactController.text;

      if (utils.isValidMobileNumber(mobileNumber)) {
        final razorpay = RazorPayment();
        razorpay.initializeRazorpay(context);
        razorpay.startPayment(totalCost, _contactController.text, email!, widget.busDetails, _passengers);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid mobile number. Please enter a valid 10-digit number.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Travel Details', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Travel details at the top
                Text(
                  '${widget.busDetails['from']} → ${widget.busDetails['to']}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${widget.busDetails['arrivalDate']}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Departure Time: ${widget.busDetails['departureTime']}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Available Seats: $availableSeats',
                  style: const TextStyle(fontSize: 16, color: Colors.green),
                ),
                const SizedBox(height: 16),

                // Passenger Input
                ..._passengers.asMap().entries.map((entry) {
                  int index = entry.key;
                  var passenger = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: passenger['name'],
                            onChanged: (value) {
                              setState(() {
                                _passengers[index]['name'] = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Passenger ${index + 1} Name',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter a name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: passenger['gender'],
                          onChanged: (value) {
                            setState(() {
                              passenger['gender'] = value!;
                            });
                          },
                          items: ['M', 'F'].map((gender) {
                            return DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                        ),
                        if (_passengers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removePassenger(index),
                          ),
                      ],
                    ),
                  );
                }).toList(),

                // Add Passenger Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: _addPassenger,
                    child: const Text(
                      'Add Passenger',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contact Number
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a contact number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Total Cost
                Text(
                  'Total Cost: ₹$totalCost',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Submit Button
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: _submitBooking,
                    child: const Text('Confirm Booking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
