import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/Firebase/storage.dart';
import 'package:findany_flutter/apis/gsheets.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:findany_flutter/xerox/showfiles.dart';
import 'package:findany_flutter/xerox/xeroxhistory.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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

  final Razorpay razorpay = Razorpay();

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
  Map<String, dynamic>? xeroxDetails= {};

  @override
  void initState() {
    super.initState();
    getData();
    totalFileCount = _uploadedFiles.length;

    //Razorpay init
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);
  }

  Future<void> getData() async {
    loadingDialog.showDefaultLoading('Getting Details...');
    DocumentReference detailsRef = FirebaseFirestore.instance.doc('XeroxDetails/DisplayDetails');
    xeroxDetails = await fireStoreService.getDocumentDetails(detailsRef);
    xeroxNote = xeroxDetails!['XeroxNote'];

    email = (await sharedPreferences.getSecurePrefsValue('Email'))!;
    setState(() {});
    EasyLoading.dismiss();
  }

  void startPayment(int amount,String number,String email) async {
    amount *= 100;
    Map<String, dynamic> options = {
      'key': 'rzp_live_kYGlb6Srm9dDRe',
      'amount': amount,
      'name': 'FindAny',
      'description': 'Xerox',
      'prefill': {'contact': number, 'email': email},
    };
    try {
      razorpay.open(options);
      print('Success: Razorpay');
    } catch (e) {
      debugPrint('Razorpay Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xerox Home'),
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
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black, // Default text color
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Note: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: xeroxNote, // Rest of the text
                    ),
                  ],
                ),
              ),
            ),
            Text(
              email,
              style: TextStyle(
                fontSize: 15,
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Xerox Name*',
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
                            MaterialPageRoute(
                              builder: (context) => ShowFiles(),
                            ),
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
                          onTap: () => _openFile(_uploadedFiles.values.toList()[index]),
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
                labelText: 'Specify any other requirements with file numbers (Extra cost applies)',
                hintText: 'spiral binding, color xerox, etc..',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null, // Allows multiple lines of text input
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
                  // Call the startPayment function when the button is pressed
                  if (totalPrice.toInt() < 1) {
                    totalPrice = 2;
                  }
                  int price = totalPrice.round();
                  print('PayingCost: $price');
                  onSubmitClicked(price);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Adjust horizontal padding as needed
                  child: Text('Pay & Submit'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Handle payment success
    print('razorpay successful ${response.paymentId}');
    // Show progress loading bar
    loadingDialog.showProgressLoading(progress, 'Uploading files...');

    // List to store uploaded file URLs
    List<String> uploadedUrls = [];
    int fileLength = _uploadedFiles.length;
    double totalprogress=0.9/fileLength;

    // Iterate through the uploaded files
    for (String value in _uploadedFiles.values) {
      File file = File(value);
      print('Value: ${file.path}');
      String? uploadedUrl = '';
      // Upload the file to Firebase Storage
      if(utils.isURL(value)){
        uploadedUrl = value;
      }else{
        uploadedUrl = await firebaseStorageHelper.uploadFile(file, 'XeroList/${utils.getTodayDate().replaceAll('/', ',')}', '${getFileName(file)}',);
      }
      print("Url: $uploadedUrl");
      if (uploadedUrl != null) {
        uploadedUrls.add(uploadedUrl);
        progress+=totalprogress;
        loadingDialog.showProgressLoading(progress, 'Uploading Files...');
      }
    }
    // Hide progress loading bar after uploading files
    print('Uploaded Urls: ${uploadedUrls}');

    int? count = await realTimeDatabase.incrementValue('Xerox/XeroxHistory');
    print("Count: $count");

    DocumentReference userRef = FirebaseFirestore.instance.doc('/UserDetails/${utils.getCurrentUserUID()}/XeroxHistory/$count');

    Map<String, dynamic> uploadData = {'ID': count,'Date': utils.getTodayDate(),'Name': _nameController.text, 'Mobile Number': _mobilenumberController.text, 'Email': email,
      'Total Price': totalPrice,'Transaction ID':response.paymentId,'Uploaded Files': uploadedUrls, 'Description':_descriptionController.text};

    List<String> sheetData = [_nameController.text, _mobilenumberController.text, email,_bindingFileController.text,_singleSideFileController.text, totalPrice.toString(),_descriptionController.text,response.paymentId!,
      'Xerox Details: ${xeroxDetails.toString()}'];
    sheetData.addAll(uploadedUrls);

    await fireStoreService.uploadMapDataToFirestore(uploadData, userRef);

    // Once all files are uploaded, update the Google Sheets
    userSheetsApi.updateCell(sheetData);
    loadingDialog.showProgressLoading(progress+0.05, 'Uploading Files...');
    utils.deleteFolder('/data/user/0/com.neelam.FindAny/cache/uploadedFiles/');
    EasyLoading.dismiss();

    // Hide progress loading bar after updating Google Sheets
    utils.showToastMessage('Request submitted', context);
    Navigator.pop(context);
  }

  void handlePaymentError(PaymentFailureResponse response) {
    // Handle payment failure
    print('razorpay unsuccessful: ${response.message}');
    utils.showToastMessage('Payment unsuccessful', context);
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
    print('razorpay External wallet ${response.walletName}');
  }

  Future<void> onSubmitClicked(int price) async {
    // Check if any required field is empty
    if (_uploadedFiles.isEmpty) {
      utils.showToastMessage('Files are missing', context);
      return;
    } else if (!utils.isValidMobileNumber(_mobilenumberController.text) || _mobilenumberController.text.isEmpty) {
      utils.showToastMessage('Enter a Valid Mobile Number', context);
      return;
    } else if (_nameController.text.length < 5  || _nameController.text.isEmpty) {
      utils.showToastMessage('Enter at least 5 letters in name', context);
      return;
    }

    startPayment(price,_mobilenumberController.text,email);
  }

  String getFileName(File file) {
    return path.basename(file.path);
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx'],
      );
      print('Result: $result');
      if (result != null) {
        Directory cacheDir = await getTemporaryDirectory();
        Directory uploadDir = Directory('${cacheDir.path}/uploadedFiles');
        if (!await uploadDir.exists()) {
          await uploadDir.create(recursive: true);
        }
        print('uploadDir: ${uploadDir.path}');
        for (var file in result.files) {
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
        utils.deleteFolder('/data/user/0/com.neelam.FindAny/cache/file_picker/');
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (error) {
      print('Error opening file: $error');
    }
  }

  @override
  void dispose() {
    _bindingFileController.dispose();
    _singleSideFileController.dispose();
    razorpay.clear();
    super.dispose();
  }
}
