import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusBookingHome extends StatefulWidget {
  @override
  _BusBookingHomeState createState() => _BusBookingHomeState();
}

class _BusBookingHomeState extends State<BusBookingHome> {

  LoadingDialog loadingDialog = LoadingDialog();
  String? _selectedTravelType;
  String? _selectedFrom;
  String? _selectedTo;
  DateTime? _selectedDate;
  String? _selectedTiming;
  String? _travelCost;
  List<String> _travelTypes = [];
  List<String> _fromPlaces = [];
  List<String> _toPlaces = [];
  List<String> _timings = [];
  List<DocumentSnapshot> _availableBuses = [];

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
    _fetchDefaultCost();
  }

  Future<void> _fetchPlaces() async {
    loadingDialog.showDefaultLoading("Getting data..");
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot doc = await firestore.collection('busbooking').doc('places').get();

      setState(() {
        _travelTypes = List<String>.from(doc['traveltype']);
        _fromPlaces = List<String>.from(doc['from']);
        _toPlaces = List<String>.from(doc['to']);
      });
    } catch (e) {
      print(e);
    } finally {
      loadingDialog.dismiss();
    }
  }

  Future<void> _fetchTimings(String travelType) async {
    loadingDialog.showDefaultLoading("Getting data..");
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot doc = await firestore.collection('busbooking').doc('places').get();

      setState(() {
        _timings = List<String>.from(doc[travelType + 'timings']);
      });
    } catch (e) {
      print(e);
    } finally {
      loadingDialog.dismiss();
    }
  }

  Future<void> _fetchDefaultCost() async {
    loadingDialog.showDefaultLoading("Getting cost data..");
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot doc = await firestore.collection('busbooking').doc('cost').get();

      setState(() {
        _travelCost = doc['defaultCost'];
        _costController.text = _travelCost ?? '';
      });
    } catch (e) {
      print(e);
    } finally {
      loadingDialog.dismiss();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.toLocal()}".split(' ')[0];  // Update text field with selected date
      });
    }
  }

  void _searchBuses() async {
    if (_selectedTravelType == null || _selectedFrom == null || _selectedTo == null || _selectedDate == null || _selectedTiming == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    loadingDialog.showDefaultLoading("Searching buses..");
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore.collection('buses')
          .where('travelType', isEqualTo: _selectedTravelType)
          .where('from', isEqualTo: _selectedFrom)
          .where('to', isEqualTo: _selectedTo)
          .where('date', isEqualTo: _selectedDate!.toIso8601String().substring(0, 10))
          .where('timing', isEqualTo: _selectedTiming)
          .get();

      setState(() {
        _availableBuses = querySnapshot.docs;
      });
    } catch (e) {
      print(e);
    } finally {
      loadingDialog.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Booking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: _selectedTravelType,
              hint: Text('Travel Type'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTravelType = newValue;
                  _selectedTiming = null;  // Reset timing selection
                  _timings = [];  // Reset timings
                  if (newValue != null) {
                    _fetchTimings(newValue);
                  }
                });
              },
              items: _travelTypes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedFrom,
              hint: Text('From'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFrom = newValue;
                });
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
              hint: Text('To'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTo = newValue;
                });
              },
              items: _toPlaces.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Select date',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedTiming,
              hint: Text('Timing'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTiming = newValue;
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
              controller: _costController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Cost',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _searchBuses,
              child: Text('Search Buses'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _availableBuses.length,
                itemBuilder: (context, index) {
                  var bus = _availableBuses[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text('Bus: ${bus['busNumber']}'),
                    subtitle: Text('Departure: ${bus['departureTime']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
