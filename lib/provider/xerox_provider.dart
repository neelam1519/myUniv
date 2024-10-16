import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/Firebase/storage.dart';
import 'package:findany_flutter/apis/gsheets.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../services/pdfscreen.dart';

class XeroxProvider with ChangeNotifier {
  final Utils utils = Utils();
  final RealTimeDatabase _realTimeDatabase = RealTimeDatabase();
  final FirebaseStorageHelper _firebaseStorageHelper = FirebaseStorageHelper();
  final FireStoreService _fireStoreService = FireStoreService();
  final UserSheetsApi _userSheetsApi = UserSheetsApi();
  final SharedPreferences _sharedPreferences = SharedPreferences();
  final LoadingDialog _loadingDialog = LoadingDialog();
  final NotificationService _notificationService = NotificationService();
  final Razorpay _razorpay = Razorpay();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobilenumberController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController bindingFileController = TextEditingController();
  final TextEditingController singleSideFileController =
      TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();

  // Variables
  final Map<String, String> _uploadedFiles = {};
  List<String> excludedItems = ['XeroxNote', 'XeroxHistory'];
  String _email = 'no email found';
  double _totalPrice = 0;
  double _progress = 0;
  String _xeroxNote = 'Contact 8501070702';
  int _totalFileCount = 0;
  String? _announcementText = "";
  Map<String, dynamic>? _xeroxDetails = {};
  int _totalPdfPages = 0;
  Map<String, int> _pdfPagesCount = {};

  // Razorpay Constants
  static const _razorpayKey = 'rzp_live_kYGlb6Srm9dDRe';
  static const _apiSecret = 'GPRg9ri7zy4r7QeRe9lT2xUx';

  // Getters and Setters
  String get email => _email;

  set email(String value) {
    _email = value;
    notifyListeners();
  }

  double get totalPrice => _totalPrice;

  set totalPrice(double value) {
    _totalPrice = value;
    notifyListeners();
  }

  double get progress => _progress;

  set progress(double value) {
    _progress = value;
    notifyListeners();
  }

  String get xeroxNote => _xeroxNote;

  set xeroxNote(String value) {
    _xeroxNote = value;
    notifyListeners();
  }

  int get totalFileCount => _totalFileCount;

  set totalFileCount(int value) {
    _totalFileCount = value;
    notifyListeners();
  }

  String? get announcementText => _announcementText;

  set announcementText(String? value) {
    _announcementText = value;
    notifyListeners();
  }

  Map<String, dynamic>? get xeroxDetails => _xeroxDetails;

  set xeroxDetails(Map<String, dynamic>? value) {
    _xeroxDetails = value;
    notifyListeners();
  }

  int get totalPdfPages => _totalPdfPages;

  set totalPdfPages(int value) {
    _totalPdfPages = value;
    notifyListeners();
  }

  Map<String, int> get pdfPagesCount => _pdfPagesCount;

  set pdfPagesCount(Map<String, int> value) {
    _pdfPagesCount = value;
    notifyListeners();
  }

  Map<String, String> get uploadedFiles => _uploadedFiles;

  Future<void> init() async {
    await getData();
    totalFileCount = _uploadedFiles.length;
    initializeRazorpay();
    await fetchAnnouncementText();
  }

  Future<void> getData() async {
    _loadingDialog.showDefaultLoading('Getting Details...');
    DocumentReference detailsRef =
        FirebaseFirestore.instance.doc('XeroxDetails/DisplayDetails');
    xeroxDetails = await _fireStoreService.getDocumentDetails(detailsRef);

    email = (await _sharedPreferences.getSecurePrefsValue('Email'))!;
    EasyLoading.dismiss();
    notifyListeners();
  }

  // Methods
  Future<String?> createOrder(int amount) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'Basic ${base64Encode(utf8.encode("$_razorpayKey:$_apiSecret"))}',
        },
        body: jsonEncode(<String, dynamic>{
          'amount': amount * 100,
          'currency': 'INR',
          'receipt': 'order_receipt_${DateTime.now().millisecondsSinceEpoch}',
          'payment_capture': 1,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['id'];
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
    _loadingDialog.showDefaultLoading('Redirecting to Payment page');
    final orderId = await createOrder(amount);
    _loadingDialog.dismiss();
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
        _razorpay.open(options);
      } catch (e) {
        debugPrint('Razorpay Error: $e');
      }
    } else {
      // Handle error in creating order
    }
  }

  Future<void> handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('razorpay successful ${response.paymentId}');
    await uploadData(response);
  }

  void handlePaymentError(PaymentFailureResponse response) {
    print('razorpay unsuccessful: ${response.message}');
    utils.showToastMessage('Payment unsuccessful');
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    print('razorpay External wallet ${response.walletName}');
  }

  Future<void> uploadData(PaymentSuccessResponse response) async {
    _loadingDialog.showProgressLoading(progress, 'Uploading files...');

    List<String> uploadedUrls = [];
    int fileLength = _uploadedFiles.length;
    double totalProgress = 0.9 / fileLength;

    int? count = await _realTimeDatabase.incrementValue('Xerox/XeroxHistory');
    String folderPath =
        "XeroList/${utils.getTodayDate().replaceAll('/', ',')}/$count";

    print('Uploading Files: $_uploadedFiles');

    int fileIndex = 1;

    for (String value in _uploadedFiles.values) {
      File file = File(value);
      String uploadedUrl = '';
      String fileName = '$fileIndex.pdf';

      uploadedUrl =
          await _firebaseStorageHelper.uploadFile(file, folderPath, fileName);

      print('Uploading url: $uploadedUrl');

      uploadedUrls.add(uploadedUrl);

      progress += totalProgress;
      _loadingDialog.showProgressLoading(progress, 'Uploading Files...');

      fileIndex++;
    }

    DocumentReference userRef = FirebaseFirestore.instance
        .doc('/UserDetails/${utils.getCurrentUserUID()}/XeroxHistory/$count');
    Map<String, dynamic> uploadData = {
      'ID': count,
      'Name': nameController.text,
      'Mobile Number': mobilenumberController.text,
      'Email': email,
      'Date': utils.getTodayDate(),
      'Total Price': totalPrice,
      'Transaction ID': response.paymentId,
      'Uploaded Files': uploadedUrls,
      'Description': descriptionController.text,
    };

    List<String> sheetData = [
      count.toString(),
      nameController.text,
      mobilenumberController.text,
      email,
      bindingFileController.text,
      singleSideFileController.text,
      totalPrice.toString(),
      descriptionController.text,
      response.paymentId!,
      'Xerox Details: ${xeroxDetails.toString()}',
    ];

    print('Xerox Details: $uploadedUrls');

    sheetData.addAll(uploadedUrls);

    await _fireStoreService.uploadMapDataToFirestore(uploadData, userRef);
    _userSheetsApi.updateCell(sheetData);
    utils.deleteFolder('/data/user/0/com.neelam.FindAny/cache/XeroxPdfs/');
    DocumentReference xeroxRef =
        FirebaseFirestore.instance.doc('AdminDetails/Xerox');
    List<String> tokens = await utils.getSpecificTokens(xeroxRef);

    _notificationService
        .sendNotification(tokens, 'Xerox Submitted', nameController.text, {});

    _loadingDialog.showProgressLoading(progress + 0.05, 'Uploading Files...');

    // Finalizing the upload process
    _loadingDialog.dismiss();
    utils.showToastMessage('Xerox request submitted successfully');

    // Reset state or any additional clean up if necessary
    nameController.clear();
    mobilenumberController.clear();
    descriptionController.clear();
    bindingFileController.clear();
    singleSideFileController.clear();
    totalAmountController.clear();
    _uploadedFiles.clear();
    totalFileCount = 0;
    totalPrice = 0;
    progress = 0;
  }

  Future<void> fetchAnnouncementText() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('AdminDetails')
          .doc('Xerox')
          .get();
      if (snapshot.exists) {
        _announcementText = snapshot.get('AnnouncementText');
        notifyListeners();
      } else {
        print('Announcement text not found');
      }
    } catch (e) {
      print('Error fetching announcement text: $e');
    }
  }

  void initializeRazorpay() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);
  }

  Future<void> onSubmitClicked(int price) async {
    if (!await utils.checkInternetConnection()) {
      utils.showToastMessage('Connect to the Internet');
      return;
    }
    if (_uploadedFiles.isEmpty) {
      utils.showToastMessage('Files are missing');
      return;
    } else if (!utils.isValidMobileNumber(mobilenumberController.text) ||
        mobilenumberController.text.isEmpty) {
      utils.showToastMessage('Enter a Valid Mobile Number');
      return;
    } else if (nameController.text.length < 5 || nameController.text.isEmpty) {
      utils.showToastMessage('Enter at least 5 letter name');
      return;
    }
    int cost = await calculatePrice();

    if (price >= cost) {
      startPayment(price, mobilenumberController.text, email);
    } else {
      utils.showToastMessage('Minimum total cost is $cost');
    }
  }

  Future<int> calculatePrice() async {
    String doubleSide =
        singleSideFileController.text.replaceAll(RegExp(r'\s+'), '');
    String binding = bindingFileController.text.replaceAll(RegExp(r'\s+'), '');

    List<String> doubleSideList = doubleSide.split(",");
    List<String> bindingList = binding.split(",");

    print("Double Side: $doubleSideList  bindingList  $bindingList");

    int fileIndex = 1;
    Map<int, int> pdfPageCounts = {};
    double totalPrice = 0;

    for (String value in _uploadedFiles.values) {
      File file = File(value);
      int pdfPages = await countPdfPages(file);
      totalPdfPages += pdfPages;
      pdfPageCounts[fileIndex] = pdfPages;
      double cost = 0;
      if (doubleSideList.contains(fileIndex.toString())) {
        cost += pdfPages * int.parse(xeroxDetails!["Double Side"]!);
      } else {
        cost += pdfPages * double.parse(xeroxDetails!["Single Side"]!);
      }

      if (bindingList.contains(fileIndex.toString())) {
        cost += int.parse(xeroxDetails!["Binding"]!);
      }

      totalPrice += cost;

      fileIndex++;
    }

    print('Total Cost: $totalPrice');
    print('Total PDF pages count: $totalPdfPages');
    print('PDF page counts: $pdfPageCounts');
    print('Total Price: $totalPrice');

    return totalPrice.toInt();
  }

  Future<int> countPdfPages(File file) async {
    // Create a PdfViewerController
    final PdfViewerController pdfViewerController = PdfViewerController();

    // Load the PDF using SfPdfViewer
    final SfPdfViewer pdfViewer = SfPdfViewer.file(
      file,
      controller: pdfViewerController,
    );

    // Wait until the document is fully loaded
    pdfViewerController.pageCount;

    // Get the total page count
    final int pageCount = pdfViewerController.pageCount;

    // Return the page count
    return pageCount;
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
          {
            _uploadedFiles[fileName] = filePath;
            notifyListeners();
          }
          print('Uploaded Files: $_uploadedFiles');
        } else {
          utils.showToastMessage('No PDF files selected');
        }
      }
    }
  }

  void viewPdfFullScreen(String? filePath, String title, BuildContext context) {
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
    _razorpay.clear();
    nameController.dispose();
    mobilenumberController.dispose();
    descriptionController.dispose();
    bindingFileController.dispose();
    singleSideFileController.dispose();
    totalAmountController.dispose();
    super.dispose();
  }
}
