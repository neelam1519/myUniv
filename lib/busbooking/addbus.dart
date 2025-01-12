import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBusScreen extends StatefulWidget {
  const AddBusScreen({Key? key}) : super(key: key);

  @override
  State<AddBusScreen> createState() => _AddBusScreenState();
}

class _AddBusScreenState extends State<AddBusScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _totalSeatsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();

  final List<String> _fromLocations = [
    'City Center',
    'University',
    'Train Station',
  ];

  final Map<String, Map<String, Map<String, List<String>>>> _schedule = {
    'City Center': {
      'Airport': {
        '2025-01-15': ['10:00 AM', '02:00 PM', '06:00 PM'],
        '2025-01-16': ['10:00 AM', '02:00 PM'],
      },
      'Bus Terminal': {
        '2025-01-15': ['09:00 AM', '01:00 PM', '05:00 PM'],
        '2025-01-16': ['09:00 AM', '01:00 PM'],
      },
    },
  };

  String? _selectedFrom;
  String? _selectedTo;
  String? _selectedDate;
  String? _selectedTime;

  Future<void> _addBus() async {
    if (_formKey.currentState!.validate()) {
      try {
        int busCount = await realTimeDatabase.incrementValue('BusCount') ?? 1;
        await FirebaseFirestore.instance.collection('buses').doc(busCount.toString()).set({
          'busNumber': busCount,
          'from': _selectedFrom,
          'to': _selectedTo,
          'date': _selectedDate,
          'time': _selectedTime,
          'totalSeats': int.parse(_totalSeatsController.text.trim()),
          'availableSeats': int.parse(_totalSeatsController.text.trim()),
          'price': double.parse(_priceController.text.trim()),
          'status': 'active',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus added successfully!')),
        );
        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding bus: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _busNumberController.clear();
    _totalSeatsController.clear();
    _priceController.clear();
    setState(() {
      _selectedFrom = null;
      _selectedTo = null;
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bus'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: _selectedFrom,
                  decoration: const InputDecoration(
                    labelText: 'From',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedFrom = value;
                      _selectedTo = null;
                      _selectedDate = null;
                      _selectedTime = null;
                    });
                  },
                  items: _fromLocations.map<DropdownMenuItem<String>>((from) {
                    return DropdownMenuItem<String>(
                      value: from,
                      child: Text(from),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Please select a starting location' : null,
                ),
                const SizedBox(height: 16.0),
                if (_selectedFrom != null)
                  DropdownButtonFormField<String>(
                    value: _selectedTo,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedTo = value;
                        _selectedDate = null;
                        _selectedTime = null;
                      });
                    },
                    items: _schedule[_selectedFrom]!
                        .keys
                        .map<DropdownMenuItem<String>>((to) {
                      return DropdownMenuItem<String>(
                        value: to,
                        child: Text(to),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Please select a destination' : null,
                  ),
                const SizedBox(height: 16.0),
                if (_selectedFrom != null && _selectedTo != null)
                  DropdownButtonFormField<String>(
                    value: _selectedDate,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedDate = value;
                        _selectedTime = null;
                      });
                    },
                    items: _schedule[_selectedFrom]![_selectedTo]!
                        .keys
                        .map<DropdownMenuItem<String>>((date) {
                      return DropdownMenuItem<String>(
                        value: date,
                        child: Text(date),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Please select a date' : null,
                  ),
                const SizedBox(height: 16.0),
                if (_selectedFrom != null && _selectedTo != null && _selectedDate != null)
                  DropdownButtonFormField<String>(
                    value: _selectedTime,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedTime = value;
                      });
                    },
                    items: _schedule[_selectedFrom]![_selectedTo]![_selectedDate]!
                        .map<DropdownMenuItem<String>>((time) {
                      return DropdownMenuItem<String>(
                        value: time,
                        child: Text(time),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Please select a time' : null,
                  ),
                const SizedBox(height: 16.0),
                if (_selectedTime != null)
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Ticket Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter the ticket price'
                        : null,
                  ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _totalSeatsController,
                  decoration: const InputDecoration(
                    labelText: 'Total Seats',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter the total seats' : null,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _addBus,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text('Add Bus'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
