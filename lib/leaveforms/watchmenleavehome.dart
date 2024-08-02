import 'package:flutter/material.dart';
import '../services/qrscanner.dart';

class WatchmenLeavehome extends StatefulWidget {
  @override
  _WatchmenhomeState createState() => _WatchmenhomeState();
}

class _WatchmenhomeState extends State<WatchmenLeavehome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Watchmen Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QRScannerScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome to Watchmen Home'),
      ),
    );
  }
}

