import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';

class BusBookingHome extends StatefulWidget {
  @override
  _BusBookingHomeState createState() => _BusBookingHomeState();
}

class _BusBookingHomeState extends State<BusBookingHome> {
  LoadingDialog loadingDialog = LoadingDialog();
  FireStoreService fireStoreService = FireStoreService();

  String? _selectedFrom;
  String? _selectedTo;
  DateTime? _selectedDate;
  String? _selectedTiming;
  double? _travelCost;
  List<String> _fromPlaces = [];
  List<String> _toPlaces = [];
  List<String> _timings = [];
  List<String> _availableDates = [];
  List<DocumentSnapshot> _availableBuses = [];

  Map<String, dynamic>? detailsData = {};
  Map<String, dynamic>? placesData = {};

  DocumentReference placesDoc = FirebaseFirestore.instance.doc("busbooking/places");
  DocumentReference detailsDoc = FirebaseFirestore.instance.doc("busbooking/Details");

  final TextEditingController _costController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();

  List<Map<String, String?>> _people = []; // List to store people details

  @override
  void initState() {
    super.initState();
    _fetchFromPlaces();
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
    loadingDialog.showDefaultLoading("Getting details... $fromPlace  $toPlace");
    try {
      detailsData = await fireStoreService.getDocumentDetails(detailsDoc);
      print('Details Data: $detailsData');
      if (detailsData != null && detailsData!.containsKey(fromPlace)) {
        Map<String, dynamic> details = detailsData![fromPlace][toPlace];

        print("Fetched Details: $details");

        setState(() {
          _availableDates = (details['Dates'] as List)
              .map((timestamp) => (timestamp as Timestamp).toDate())
              .map((date) => "${date.toLocal()}".split(' ')[0])
              .toList();
          _timings = List<String>.from(details['Timings']);
          _travelCost = double.tryParse(details['Cost'].toString()) ?? 0;
          _selectedDate = _availableDates.isNotEmpty ? DateTime.parse(_availableDates.first) : null;
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
    if (_selectedFrom == null || _selectedTo == null || _selectedDate == null || _selectedTiming == null ) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if(_people.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the Pesons details')),
      );
      return;
    }

    print('Details $_people $_selectedFrom  $_selectedTo $_selectedDate  $_selectedTiming');

    // Your logic to search for buses goes here.
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
                value: _selectedDate != null ? "${_selectedDate!.toLocal()}".split(' ')[0] : null,
                decoration: InputDecoration(
                  labelText: 'Select Date',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDate = DateTime.parse(newValue!);
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
