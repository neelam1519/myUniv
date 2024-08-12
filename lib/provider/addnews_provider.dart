import 'dart:io';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class AddNewsProvider with ChangeNotifier {
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();
  FireStoreService fireStoreService = FireStoreService();
  Utils utils = Utils();
  NotificationService notificationService = NotificationService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _detailsController;
  PlatformFile? _pickedFile;
  bool _isLoading = false;
  String? _error;

  GlobalKey<FormState> get formKey => _formKey;
  TextEditingController get titleController => _titleController;
  TextEditingController get summaryController => _summaryController;
  TextEditingController get detailsController => _detailsController;
  PlatformFile? get pickedFile => _pickedFile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  set titleController(TextEditingController controller) {
    _titleController = controller;
    notifyListeners();
  }

  set summaryController(TextEditingController controller) {
    _summaryController = controller;
    notifyListeners();
  }

  set detailsController(TextEditingController controller) {
    _detailsController = controller;
    notifyListeners();
  }

  set pickedFile(PlatformFile? file) {
    _pickedFile = file;
    notifyListeners();
  }

  set isLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  set error(String? err) {
    _error = err;
    notifyListeners();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      pickedFile = result.files.first;
    }
  }

  Future<String?> _uploadFile() async {
    if (_pickedFile == null) return null;
    final fileName = path.basename(_pickedFile!.path!);
    final destination = 'news/${utils.getTodayDate().replaceAll('/', '-')}/$fileName';

    try {
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(File(_pickedFile!.path!));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> saveNews(String documentID, BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      isLoading = true;

      final pdfUrl = await _uploadFile();
      int? count = await realTimeDatabase.incrementValue('News');
      Map<String, dynamic> data = {
        'title': _titleController.text,
        'summary': _summaryController.text,
        'details': _detailsController.text,
        'pdfUrl': pdfUrl,
        'timestamp': Timestamp.now(),
      };

      if (documentID.isNotEmpty) {
        DocumentReference documentReference = FirebaseFirestore.instance.doc('/news/$documentID');
        fireStoreService.deleteDocument(documentReference);
      }

      print('News Data: $data');
      DocumentReference newsRef = FirebaseFirestore.instance.doc('news/${count.toString()}');
      fireStoreService.uploadMapDataToFirestore(data, newsRef);

      List<String> tokens = await utils.getAllTokens();
      Map<String, String> additionalData = {'source': 'NewsListScreen'};
      notificationService.sendNotification(tokens, 'University News', _titleController.text, additionalData);

      isLoading = false;

      Navigator.of(context).pop();
    }
  }

  void disposeControllers() {
    _titleController.dispose();
    _summaryController.dispose();
    _detailsController.dispose();
  }
}
