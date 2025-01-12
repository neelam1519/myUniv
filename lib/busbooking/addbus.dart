import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController _departureDateController = TextEditingController();
  final TextEditingController _departureTimeController = TextEditingController();
  final TextEditingController _arrivalDateController = TextEditingController();
  final TextEditingController _arrivalTimeController = TextEditingController();
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();

  final List<String> _fromLocations = [
    'City Center',
    'University',
    'Train Station',
    'Airport',
    'Bus Terminal',
  ];

  final List<String> _toLocations = [
    'City Center',
    'University',
    'Train Station',
    'Airport',
    'Bus Terminal',
  ];

  String? _selectedFrom;
  String? _selectedTo;

  Future<void> _addBus() async {
    if (_formKey.currentState!.validate()) {
      try {
        int busCount = await realTimeDatabase.incrementValue('BusCount') ?? 1;
        await FirebaseFirestore.instance.collection('buses').doc(busCount.toString()).set({
          'busNumber': busCount,
          'from': _selectedFrom,
          'to': _selectedTo,
          'departureDate': _departureDateController.text.trim(),
          'departureTime': _departureTimeController.text.trim(),
          'arrivalDate': _arrivalDateController.text.trim(),
          'arrivalTime': _arrivalTimeController.text.trim(),
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
    _departureDateController.clear();
    _departureTimeController.clear();
    _arrivalDateController.clear();
    _arrivalTimeController.clear();
    setState(() {
      _selectedFrom = null;
      _selectedTo = null;
    });
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime != null) {
      setState(() {
        controller.text = selectedTime.format(context);
      });
    }
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
                DropdownButtonFormField<String>(
                  value: _selectedTo,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedTo = value;
                    });
                  },
                  items: _toLocations.map<DropdownMenuItem<String>>((to) {
                    return DropdownMenuItem<String>(
                      value: to,
                      child: Text(to),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Please select a destination' : null,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _arrivalDateController,
                  decoration: InputDecoration(
                    labelText: 'Arrival Date',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(_arrivalDateController),
                    ),
                  ),
                  readOnly: true,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please select an arrival date'
                      : null,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _arrivalTimeController,
                  decoration: InputDecoration(
                    labelText: 'Arrival Time',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () => _pickTime(_arrivalTimeController),
                    ),
                  ),
                  readOnly: true,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please select an arrival time'
                      : null,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _departureDateController,
                  decoration: InputDecoration(
                    labelText: 'Departure Date',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(_departureDateController),
                    ),
                  ),
                  readOnly: true,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please select a departure date'
                      : null,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _departureTimeController,
                  decoration: InputDecoration(
                    labelText: 'Departure Time',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () => _pickTime(_departureTimeController),
                    ),
                  ),
                  readOnly: true,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please select a departure time'
                      : null,
                ),
                const SizedBox(height: 16.0),
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
