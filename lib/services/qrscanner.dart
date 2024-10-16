import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedData;
  Map<String, dynamic>? documentData = {};
  Map<String, dynamic>? leaveData = {};
  bool isLoading = false;
  String leaveID = "";

  LoadingDialog loadingDialog = LoadingDialog();
  Utils utils = Utils();
  FireStoreService fireStoreService = FireStoreService();

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isLoading) {
        setState(() {
          scannedData = scanData.code;
          isLoading = true;
        });
        await _fetchDataFromFirestore(scanData.code);
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  Future<void> _fetchDataFromFirestore(String? docId) async {
    loadingDialog.showDefaultLoading('Getting Details');
    if (docId == null) return;

    leaveID = docId;
    DocumentReference documentReference =
        FirebaseFirestore.instance.doc("LeaveForms/$docId");
    print('Document Reference: ${documentReference.path}');

    leaveData = await fireStoreService.getDocumentDetails(documentReference);

    String? uid = await utils.getCurrentUserUID();

    DocumentReference userRef =
        FirebaseFirestore.instance.doc("UserDetails/$uid");
    Map<String, dynamic>? userData =
        await fireStoreService.getDocumentDetails(userRef);

    documentData!.addAll({
      "APPROVAL STATUS": leaveData!["finalApproval"]["status"],
      "FROM": leaveData!["fromDate"],
      "TO": leaveData!["toDate"],
      "REGISTRATION NUMBER": userData!['Registration Number'],
      "PROFILE IMAGE": userData["ProfileImageURL"]
    });

    print('LeaveData: $leaveData');
    print("UserData: $userData");
    print('DocumentData: $documentData');

    try {
      setState(() {
        documentData;
      });
    } catch (e) {
      print(e);
    }
    loadingDialog.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.green,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 250,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: documentData == null
                  ? const Center(child: Text('Scan a QR code'))
                  : Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Approval Status: ${documentData!["APPROVAL STATUS"] ?? 'CHECKING'}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: documentData![
                                                    "APPROVAL STATUS"] ==
                                                'APPROVED'
                                            ? Colors.green
                                            : documentData![
                                                        "APPROVAL STATUS"] ==
                                                    'PENDING'
                                                ? Colors.red
                                                : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'From: ${documentData!["FROM"] ?? 'No from date found'}',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    Text(
                                      'To: ${documentData!["TO"] ?? 'No to date found'}',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: Image.network(
                                documentData!["PROFILE IMAGE"] ??
                                    'https://firebasestorage.googleapis.com/v0/b/findany-84c36.appspot.com/o/Logo%20Imgae%2Ftransperentlogo.png?alt=media&token=025da46c-07c9-43ae-93f5-e46a509e5ab5',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  loadingDialog.showDefaultLoading("uploading Data");
                  // Add your button action here

                  DocumentReference reference =
                      FirebaseFirestore.instance.doc("LeaveForms/$leaveID");
                  Map<String, dynamic> data = {leaveID: reference};
                  Map<String, dynamic> outData = {
                    "OUT TIME": utils.getCurrentTime()
                  };
                  fireStoreService.uploadMapDataToFirestore(outData, reference);

                  DocumentReference leaveRef = FirebaseFirestore.instance
                      .doc("/AcademicDetails/WATCHMEN APPROVED FORMS");
                  fireStoreService.uploadMapDataToFirestore(data, leaveRef);

                  loadingDialog.dismiss();
                  Navigator.pop(context);
                },
                child: const Text('APPROVED'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
