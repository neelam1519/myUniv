import 'package:flutter/material.dart';

class BusList extends StatefulWidget {
  final String selectedFrom;
  final String selectedTo;
  final DateTime selectedDate;

  BusList({
    required this.selectedFrom,
    required this.selectedTo,
    required this.selectedDate,
  });

  @override
  _BusListState createState() => _BusListState();
}

class _BusListState extends State<BusList> {
  @override
  void initState() {
    super.initState();
    // Fetch buses based on the selected from, to, and date
    _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    // Implement the logic to fetch buses based on widget.selectedFrom, widget.selectedTo, and widget.selectedDate
    // For now, we'll just simulate a delay
    await Future.delayed(Duration(seconds: 2));
    // After fetching, you can update the state with the fetched data
    setState(() {
      // Update state with the fetched data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Buses'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Buses from ${widget.selectedFrom} to ${widget.selectedTo} on ${widget.selectedDate.toLocal().toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: 10, // Replace with actual bus count
                itemBuilder: (context, index) {
                  // Replace with actual bus data
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text('Bus $index'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Departure: 10:00 AM'), // Replace with actual data
                          Text('From: ${widget.selectedFrom} To: ${widget.selectedTo}'), // Replace with actual data
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }


}

