import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Barcode? result;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      // Request permission
      await Permission.camera.request();
    } else if (status.isPermanentlyDenied) {
      // Open settings if the permission is permanently denied
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Scanner'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.green,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 300,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: (result != null)
                    ? Text('Barcode Type: ${formatToString(result!.format)}   Data: ${result!.code}')
                    : Text('Scan a code'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      // Return the scanned QR code data to the previous screen
      Navigator.pop(context, result!.code);
    }, onError: (error) {
      print('Error: $error');
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

String formatToString(BarcodeFormat format) {
  switch (format) {
    case BarcodeFormat.aztec:
      return 'Aztec';
    case BarcodeFormat.codabar:
      return 'Codabar';
    case BarcodeFormat.code128:
      return 'Code 128';
    case BarcodeFormat.code39:
      return 'Code 39';
    case BarcodeFormat.code93:
      return 'Code 93';
    case BarcodeFormat.dataMatrix:
      return 'Data Matrix';
    case BarcodeFormat.ean13:
      return 'EAN 13';
    case BarcodeFormat.ean8:
      return 'EAN 8';
    case BarcodeFormat.itf:
      return 'ITF';
    case BarcodeFormat.pdf417:
      return 'PDF 417';
    case BarcodeFormat.qrcode:
      return 'QR Code';
    case BarcodeFormat.upcA:
      return 'UPC A';
    case BarcodeFormat.upcE:
      return 'UPC E';
    default:
      return 'Unknown';
  }
}
