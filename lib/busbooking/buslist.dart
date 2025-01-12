import 'package:findany_flutter/busbooking/traveldetails.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'fetch_buslist_provider.dart';

class BusList extends StatefulWidget {
  final String fromLocation;
  final String toLocation;
  final DateTime selectedDate;

  const BusList({
    Key? key,
    required this.fromLocation,
    required this.toLocation,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<BusList> createState() => _BusListState();
}

class _BusListState extends State<BusList> {
  String? selectedBusId;  // Variable to track selected bus

  @override
  void initState() {
    super.initState();

    String formattedDate = widget.selectedDate.toString().split(' ')[0]; // YYYY-MM-DD

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FetchBusListProvider>(context, listen: false).fetchBusList(
        fromLocation: widget.fromLocation,
        toLocation: widget.toLocation,
        selectedDate: formattedDate,
      );
    });
  }

  void _editRouteAndDate() {
    // Implement route and date editing logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.fromLocation} → ${widget.toLocation}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              "Date: ${widget.selectedDate.toLocal().toString().split(' ')[0]}",
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editRouteAndDate,
          ),
        ],
        backgroundColor: Colors.blue.shade900,
      ),
      body: Consumer<FetchBusListProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return _buildShimmerList();
          if (provider.buses.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            itemCount: provider.buses.length,
            itemBuilder: (context, index) {
              var bus = provider.buses[index];
              return GestureDetector(
                onTap: () {
                    selectedBusId = bus['busNumber'].toString();
                    print('BusNumber: $selectedBusId');

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  TravelDetailsPage(busDetails: bus),
                      ),
                    );

                },
                child: _buildBusCard(bus, bus['busNumber'].toString() == selectedBusId),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: Shimmer.fromColors(
            baseColor: Colors.black12,
            highlightColor: Colors.black26,
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bus_alert, size: 80, color: Colors.black54),
          SizedBox(height: 16),
          Text(
            "No buses available for the selected route.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus, bool isSelected) {
    final int seatsLeft = bus['seatsLeft'] ?? 0;
    final String arrivalTime = bus['arrivalTime'] ?? "N/A";
    final String departureTime = bus['departureTime'] ?? "N/A";
    final String duration = bus['duration'] ?? "N/A";
    final double price = bus['price'] ?? 0.0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      color: isSelected ? Colors.blue.shade50 : Colors.white,  // Highlight selected card
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(arrivalTime, style: _boldBlueStyle()),
                Container(width: 30, height: 1, color: Colors.black),
                Text(duration, style: _regularBlackStyle()),
                Container(width: 30, height: 1, color: Colors.black),
                Text(departureTime, style: _boldBlueStyle()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_seat, size: 20, color: seatsLeft < 15 ? Colors.red : Colors.blue.shade900),
                    const SizedBox(width: 8),
                    Text(
                      "$seatsLeft Seats Left",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: seatsLeft < 15 ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.currency_rupee, size: 20),
                    Text("$price", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            if (seatsLeft < 15)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Book Fast!",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  TextStyle _boldBlueStyle() => TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900);
  TextStyle _regularBlackStyle() => const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black87);
}
