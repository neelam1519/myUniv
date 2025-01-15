import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PaymentStatus extends StatefulWidget {
  final Map<String, dynamic> busDetails;
  final List<Map<String, dynamic>> passengerDetails;
  final bool isPaymentSuccessful;
  final String ticketStatus; // "Confirmed" or "WaitingList"
  final int waitingListCount; // Total waiting list count

  PaymentStatus({
    required this.busDetails,
    required this.passengerDetails,
    required this.isPaymentSuccessful,
    required this.ticketStatus,
    required this.waitingListCount,
  });

  @override
  _PaymentStatusState createState() => _PaymentStatusState();
}

class _PaymentStatusState extends State<PaymentStatus> {
  @override
  void initState() {
    super.initState();

    // Redirect to homepage after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Choose the appropriate Lottie animation based on payment success or failure
    String lottieAnimation = widget.isPaymentSuccessful
        ? 'assets/lotties/payment_success.json'
        : 'assets/lotties/payment_failed.json';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: widget.isPaymentSuccessful ? Colors.green : Colors.red,
      ),
      body: Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lottie animation centered
              Padding(
                padding: const EdgeInsets.only(top: 40.0, left: 30), // Adjust the left padding
                child: Align(
                  alignment: Alignment.centerLeft, // Align to the left within the available space
                  child: Lottie.asset(
                    lottieAnimation,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Text(
                widget.isPaymentSuccessful
                    ? "Bus Ticket Booked Successfully!"
                    : "Bus Ticket Booking Failed!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.isPaymentSuccessful ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 20),

              if(widget.isPaymentSuccessful)
                _buildTicketStatus(),

              const SizedBox(height: 20),

              // Bus Details Section
              _buildDetailsSection(
                'Bus Details',
                [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildDetailRow('From', widget.busDetails['from']),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDetailRow('To', widget.busDetails['to']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildDetailRow('Bus Date', widget.busDetails['arrivalDate']),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDetailRow('Bus Time', widget.busDetails['arrivalTime']),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Passenger Details Section
              _buildDetailsSection(
                'Passenger Details',
                widget.passengerDetails.map(_buildPassengerRow).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.ticketStatus == "Confirmed" ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.ticketStatus == "Confirmed" ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ticket Status: ${widget.ticketStatus}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.ticketStatus == "Confirmed" ? Colors.green : Colors.red,
            ),
          ),
          if (widget.ticketStatus == "WaitingList")
            Text(
              "Your position in the waiting list: ${widget.waitingListCount}",
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
        ],
      ),
    );
  }

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
