import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PaymentStatus extends StatelessWidget {
  final Map<String, dynamic> busDetails;
  final List<Map<String, dynamic>> passengerDetails;
  final bool isPaymentSuccessful;

  PaymentStatus({
    required this.busDetails,
    required this.passengerDetails,
    required this.isPaymentSuccessful,
  });

  @override
  Widget build(BuildContext context) {
    // Choose the appropriate Lottie animation based on payment success or failure
    String lottieAnimation = isPaymentSuccessful
        ? 'assets/lotties/payment_success.json' // Replace with your success animation file path
        : 'assets/lotties/payment_failed.json'; // Replace with your failure animation file path

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: isPaymentSuccessful ? Colors.green : Colors.red,
      ),
      body: Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lottie animation centered in a Row
              Padding(
                padding: const EdgeInsets.only(top: 40.0, right: 150),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Center Lottie horizontally
                  children: [
                    Lottie.asset(
                      lottieAnimation,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20), // Space between Lottie and the next section

              // Bus Details Section
              _buildDetailsSection(
                'Bus Details',
                [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildDetailRow('From', busDetails['from']),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDetailRow('To', busDetails['to']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildDetailRow('Bus Date', busDetails['arrivalDate']),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDetailRow('Bus Time', busDetails['arrivalTime']),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Passenger Details Section
              _buildDetailsSection(
                'Passenger Details',
                passengerDetails.map(_buildPassengerRow).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a simple text row for bus details
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value ?? 'Not Available',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to display passenger information
  Widget _buildPassengerRow(Map<String, dynamic> passenger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            '${passenger['name']} - Gender: ${passenger['gender']}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Helper method to create a details section with a title
  Widget _buildDetailsSection(String title, List<Widget> content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 10),
          ...content,
        ],
      ),
    );
  }
}
