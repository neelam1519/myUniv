import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'fetch_buslist_provider.dart';

class BusList extends StatefulWidget {
  final String selectedFrom;
  final String selectedTo;
  final DateTime selectedDate;

  const BusList({
    super.key,
    required this.selectedFrom,
    required this.selectedTo,
    required this.selectedDate,
  });

  @override
  State<BusList> createState() => _BusListState();
}

class _BusListState extends State<BusList> {
  FetchBuslistProvider? fetchBuslistProvider;

  @override
  void initState() {
    super.initState();
    fetchBuslistProvider = Provider.of<FetchBuslistProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchBuslistProvider?.fetchBuses();
    });
  }

  // Future<void> _fetchBuses() async {
  //   await Future.delayed(const Duration(seconds: 2));
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Buses'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Buses from ${widget.selectedFrom} to ${widget.selectedTo} on ${widget.selectedDate.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 16.0),
            Consumer<FetchBuslistProvider>(
              builder: (context, busListProvider, child) {
                return Expanded(
                  child: ListView.builder(
                    itemCount: busListProvider.count,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text('Bus $index'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Departure: 10:00 AM'),
                              Text('From: ${widget.selectedFrom} To: ${widget.selectedTo}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            )
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}
