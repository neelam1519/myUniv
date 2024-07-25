import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/Firebase/storage.dart';
import 'package:findany_flutter/apis/gsheets.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:findany_flutter/xerox/showfiles.dart';
import 'package:findany_flutter/xerox/xeroxhistory.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import '../services/pdfscreen.dart';


class XeroxHome extends StatefulWidget {

  @override
  _XeroxHomeState createState() => _XeroxHomeState();
}

class _XeroxHomeState extends State<XeroxHome> {

  Utils utils = new Utils();
  RealTimeDatabase realTimeDatabase = new RealTimeDatabase();
  FirebaseStorageHelper firebaseStorageHelper = new FirebaseStorageHelper();
  FireStoreService fireStoreService = new FireStoreService();
  UserSheetsApi userSheetsApi = new UserSheetsApi();
  SharedPreferences sharedPreferences = new SharedPreferences();
  LoadingDialog loadingDialog = new LoadingDialog();
  NotificationService notificationService = new NotificationService();

  Razorpay razorpay = new Razorpay();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  TextEditingController _nameController = TextEditingController();
  TextEditingController _mobilenumberController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _bindingFileController = TextEditingController();
  TextEditingController _singleSideFileController = TextEditingController();
  TextEditingController _totalAmountController = TextEditingController();

  Map<String, String> _uploadedFiles = {};
  List<String> excludedItems = ['XeroxNote','XeroxHistory'];

  String email='no email found';
  double totalPrice=0;
  double progress=0;
  String xeroxNote='Contact 8501070702';
  int totalFileCount=0;
  String? _announcementText = "";
  Map<String, dynamic>? xeroxDetails= {};
  int totalPdfPages = 0;

  Map<String,int> pdfPagesCount = {};
  //Razorpay
  String apiUrl = 'https://api.razorpay.com/v1/orders';
  static const _razorpayKey = 'rzp_live_kYGlb6Srm9dDRe';
  static const _apiSecret = 'GPRg9ri7zy4r7QeRe9lT2xUx';

  @override
  void initState() {
    super.initState();
    getData();
    totalFileCount = _uploadedFiles.length;
    initializeRazorpay();
    _fetchAnnouncementText();
  }


  initializeRazorpay() async {

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);

  }


  Future<void> _fetchAnnouncementText() async {
    final DatabaseReference announcementRef = _database.ref('Xerox');
    announcementRef.onValue.listen((event) {
      final DataSnapshot snapshot = event.snapshot;
      if (snapshot.exists) {
        setState(() {
          print("Values in the Xerox: ${snapshot.value}");
          _announcementText = (snapshot.value as Map)['Announcement'];
        });
      } else {
        setState(() {
          _announcementText = null;
        });
      }
    });
  }

  Future<void> getData() async {
    loadingDialog.showDefaultLoading('Getting Details...');
    DocumentReference detailsRef = FirebaseFirestore.instance.doc('XeroxDetails/DisplayDetails');
    xeroxDetails = await fireStoreService.getDocumentDetails(detailsRef);

    email = (await sharedPreferences.getSecurePrefsValue('Email'))!;
    setState(() {});
    EasyLoading.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xerox'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => XeroxHistory()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_announcementText != null && _announcementText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
                child: Linkify(
                  text: _announcementText!,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  linkStyle: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  onOpen: (link) async {
                    if (await canLaunch(link.url)) {
                      await launch(link.url);
                    } else {
                      throw 'Could not launch ${link.url}';
                    }
                  },
                ),
              ),
            SizedBox(height: 15),
            Text(
              email,
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Xerox copy name*',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _mobilenumberController,
              decoration: InputDecoration(
                labelText: 'Mobile Number*',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: pickFile,
                        child: Text('Upload File'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ShowFiles()),
                          ).then((value) {
                            if (value != null) {
                              setState(() {
                                _uploadedFiles.addAll(value);
                                totalFileCount = _uploadedFiles.length;
                              });
                            }
                          });
                        },
                        child: Text('Select Files'),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int index = 0; index < _uploadedFiles.length; index++)
                        ListTile(
                          title: Text('${index + 1}. ${_uploadedFiles.keys.toList()[index]}'),
                          onTap: () => viewPdfFullScreen(_uploadedFiles.values.toList()[index], _uploadedFiles.values.toList()[index].split('/').last),
                          trailing: IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                utils.deleteFileInCache(_uploadedFiles.values.toList()[index]);
                                _uploadedFiles.remove(_uploadedFiles.keys.toList()[index]);
                                totalFileCount = _uploadedFiles.length;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _bindingFileController,
              decoration: InputDecoration(
                labelText: 'File numbers for binding (default is no binding)',
                hintText: 'ex -1,3',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _singleSideFileController,
              decoration: InputDecoration(
                labelText: '2-side print file numbers (default is 1-side print)',
                hintText: 'ex -2,4',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Specify other requirements with file numbers',
                hintText: 'color ,spiral biniding...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
            SizedBox(height: 20),
            DataTable(
              columns: [
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Price')),
              ],
              rows: [
                for (var entry in xeroxDetails!.entries)
                  if (!excludedItems.contains(entry.key))
                    DataRow(cells: [
                      DataCell(Text(entry.key)),
                      DataCell(Text(entry.value.toString())),
                    ]),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _totalAmountController,
              decoration: InputDecoration(
                labelText: 'Total Amount',
                hintText: 'Calculate the price and enter here',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  totalPrice = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (totalPrice.toInt() < 1) {
                    totalPrice = 2;
                  }
                  int price = totalPrice.round();
                  print('PayingCost: $price');
                  onSubmitClicked(price);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Pay & Submit'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> createOrder(int amount) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode("$_razorpayKey:$_apiSecret"))}',
        },
        body: jsonEncode(<String, dynamic>{
          'amount': amount *100,
          'currency': 'INR',
          'receipt': 'order_receipt_${DateTime.now().millisecondsSinceEpoch}',
          'payment_capture': 1, // Auto capture payment
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['id']; // Return the order ID
      } else {
        print('Failed to create order: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  void startPayment(int amount, String number, String email) async {
    loadingDialog.showDefaultLoading('Redirecting to Payment page');
    final orderId = await createOrder(amount);
    loadingDialog.dismiss();
    print('Order ID: $orderId');
    if (orderId != null) {
      var options = {
        'key': _razorpayKey,
        'amount': amount * 100,
        'currency': 'INR',
        'name': 'FindAny',
        'description': 'Xerox',
        'prefill': {'contact': number, 'email': email},
        'order_id': orderId,
      };
      try {
        razorpay.open(options);
      } catch (e) {
        debugPrint('Razorpay Error: $e');
      }
    } else {
      // Handle error in creating order
    }
  }

  Future<void> handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('razorpay successful ${response.paymentId}');
    uploadData(response);

  }


  void handlePaymentError(PaymentFailureResponse response) {
    print('razorpay unsuccessful: ${response.message}');
    utils.showToastMessage('Payment unsuccessful', context);
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    print('razorpay External wallet ${response.walletName}');
  }

  Future<void> uploadData(PaymentSuccessResponse response) async {
    loadingDialog.showProgressLoading(progress, 'Uploading files...');

    List<String> uploadedUrls = [];
    int fileLength = _uploadedFiles.length;
    double totalProgress = 0.9 / fileLength;

    int? count = await realTimeDatabase.incrementValue('Xerox/XeroxHistory');
    String folderPath = "XeroList/${utils.getTodayDate().replaceAll('/', ',')}/$count";

    print('Uploading Files: $_uploadedFiles');

    int fileIndex = 1;

    for (String value in _uploadedFiles.values) {
      File file = File(value);
      String uploadedUrl = '';
      String fileName = '${fileIndex}.pdf';

      uploadedUrl = await firebaseStorageHelper.uploadFile(file, folderPath, fileName);

      print('Uploading url: $uploadedUrl');

      uploadedUrls.add(uploadedUrl);

      progress += totalProgress;
      loadingDialog.showProgressLoading(progress, 'Uploading Files...');

      fileIndex++;
    }

    DocumentReference userRef = FirebaseFirestore.instance.doc('/UserDetails/${utils.getCurrentUserUID()}/XeroxHistory/$count');
    Map<String, dynamic> uploadData = {
      'ID': count,
      'Name': _nameController.text,
      'Mobile Number': _mobilenumberController.text,
      'Email': email,
      'Date': utils.getTodayDate(),
      'Total Price': totalPrice,
      'Transaction ID': response.paymentId,
      'Uploaded Files': uploadedUrls,
      'Description': _descriptionController.text,
    };

    List<String> sheetData = [
      count.toString(),
      _nameController.text,
      _mobilenumberController.text,
      email,
      _bindingFileController.text,
      _singleSideFileController.text,
      totalPrice.toString(),
      _descriptionController.text,
      response.paymentId!,
      'Xerox Details: ${xeroxDetails.toString()}',
    ];

    print('Xerox Details: $uploadedUrls');

    sheetData.addAll(uploadedUrls);

    await fireStoreService.uploadMapDataToFirestore(uploadData, userRef);
    userSheetsApi.updateCell(sheetData);
    utils.deleteFolder('/data/user/0/com.neelam.FindAny/cache/XeroxPdfs/');
    DocumentReference xeroxRef = FirebaseFirestore.instance.doc('AdminDetails/Xerox');
    List<String> tokens = await utils.getSpecificTokens(xeroxRef);

    notificationService.sendNotification(tokens, 'Xerox Submitted', _nameController.text, {});

    loadingDialog.showProgressLoading(progress + 0.05, 'Uploading Files...');

    utils.showToastMessage('Request submitted', context);
    EasyLoading.dismiss();
    Navigator.pop(context);
  }


  Future<int> calculatePrice() async{

    String doubleSide = _singleSideFileController.text.replaceAll(RegExp(r'\s+'), '');
    String binding = _bindingFileController.text.replaceAll(RegExp(r'\s+'), '');

    List<String> doubleSideList = doubleSide.split(",");
    List<String> bindingList = binding.split(",");

    print("Double Side: $doubleSideList  bindingList  $bindingList");

    int fileIndex = 1;
    Map<int, int> pdfPageCounts = {};
    double totalPrice = 0;


    for (String value in _uploadedFiles.values) {
      File file = File(value);
      // Count the number of pages in the PDF using pdfrx
      int pdfPages = await countPdfPages(file);
      totalPdfPages += pdfPages;

      // Store the page count for this PDF with file number as key
      pdfPageCounts[fileIndex] = pdfPages;

      // Calculate the cost for this file
      double cost = 0;
      if (doubleSideList.contains(fileIndex.toString())) {
        cost += pdfPages * int.parse(xeroxDetails!["Double Side"]!); // Double-sided printing cost
      } else {
        cost += pdfPages * double.parse(xeroxDetails!["Single Side"]!); // Single-sided printing cost
      }

      if (bindingList.contains(fileIndex.toString())) {
        cost += int.parse(xeroxDetails!["Binding"]!);
      }

      totalPrice += cost;

      fileIndex++; // Increment file index after processing
    }

    print('Total Cost: $totalPrice');
    print('Total PDF pages count: $totalPdfPages'); // Print the total number of PDF pages
    print('PDF page counts: $pdfPageCounts'); // Print the page counts for each PDF
    print('Total Price: $totalPrice'); // Print the total price

    return totalPrice.toInt();

  }

  Future<int> countPdfPages(File file) async {
    final pdfDocument = await PdfDocument.openFile(file.path);
    return pdfDocument.pages.length;
  }

  String getFileName(File file) {
    return path.basename(file.path);
  }


  Future<void> onSubmitClicked(int price) async {
    if(!await utils.checkInternetConnection()){
      utils.showToastMessage('Connect to the Internet', context);
      return;
    }
    if (_uploadedFiles.isEmpty) {
      utils.showToastMessage('Files are missing', context);
      return;
    } else if (!utils.isValidMobileNumber(_mobilenumberController.text) || _mobilenumberController.text.isEmpty) {
      utils.showToastMessage('Enter a Valid Mobile Number', context);
      return;
    } else if (_nameController.text.length < 5  || _nameController.text.isEmpty) {
      utils.showToastMessage('Enter at least 5 letter name', context);
      return;
    }
    int cost = await calculatePrice();

    if(price >= cost){
      startPayment(price,_mobilenumberController.text,email);
    }else{
      utils.showToastMessage('Minimum total cost is $cost', context);
    }
  }


  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      Directory cacheDir = await getTemporaryDirectory();
      Directory uploadDir = Directory('${cacheDir.path}/xeroxPdfs');
      if (!await uploadDir.exists()) {
        await uploadDir.create(recursive: true);
      }
      print('uploadDir: ${uploadDir.path}');

      for (var file in result.files) {
        if (file.extension == 'pdf') {
          String fileName = file.name;
          File pickedFile = File(file.path!);
          File newFile = File('${uploadDir.path}/$fileName');
          await pickedFile.copy(newFile.path);
          String filePath = newFile.path;
          print('File uploaded: $fileName at $filePath');
          setState(() {
            _uploadedFiles[fileName] = filePath;
          });
        }
      }
      print('Uploaded Files: $_uploadedFiles');
    } else {
      utils.showToastMessage('No PDF files selected', context);
    }
  }
  void viewPdfFullScreen(String? filePath, String title) {
    if (filePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFScreen(filePath: filePath, title: title),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bindingFileController.dispose();
    _singleSideFileController.dispose();
    loadingDialog.dismiss();
    super.dispose();
  }
}
