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

class AddNews extends StatefulWidget {
  final String title;
  final String summary;
  final String details;
  final String? pdfUrl;
  final String documentID;

  AddNews({required this.title, required this.summary, required this.details, this.pdfUrl, required this.documentID});

  @override
  _AddNewsState createState() => _AddNewsState();
}

class _AddNewsState extends State<AddNews>{
  RealTimeDatabase realTimeDatabase = new RealTimeDatabase();
  FireStoreService fireStoreService = new FireStoreService();
  Utils utils = new Utils();
  NotificationService notificationService = new NotificationService();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _detailsController;
  PlatformFile? pickedFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _summaryController = TextEditingController(text: widget.summary);
    _detailsController = TextEditingController(text: widget.details);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        pickedFile = result.files.first;
      });
    }
  }

  Future<String?> _uploadFile() async {
    if (pickedFile == null) return null;
    final fileName = path.basename(pickedFile!.path!);
    final destination = 'news/${utils.getTodayDate().replaceAll('/', '-')}/$fileName';

    try {
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(File(pickedFile!.path!));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _saveNews() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final pdfUrl = await _uploadFile();
      int? count =await realTimeDatabase.incrementValue('News');
      Map<String,dynamic> data = {'title': _titleController.text, 'summary': _summaryController.text, 'details': _detailsController.text,
        'pdfUrl': pdfUrl, 'timestamp': Timestamp.now()};

      if(widget.documentID.isNotEmpty){
        DocumentReference documentReference = FirebaseFirestore.instance.doc('/news/${widget.documentID}');
        fireStoreService.deleteDocument(documentReference);
      }

      print('News Data: ${data}');
      DocumentReference newsRef = FirebaseFirestore.instance.doc('news/${count.toString()}');
      fireStoreService.uploadMapDataToFirestore(data, newsRef);

      List<String> tokens = await utils.getAllTokens();
      Map<String,String> additionalData = {'source':'NewsListScreen'};
      notificationService.sendNotification(tokens, 'University News',_titleController.text,additionalData);

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add News'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _summaryController,
                  decoration: InputDecoration(labelText: 'Summary'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a summary';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _detailsController,
                  decoration: InputDecoration(labelText: 'Details'),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter details';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: Icon(Icons.attach_file),
                  label: Text('Upload File'),
                ),
                SizedBox(height: 8.0),
                Text(
                  pickedFile != null ? pickedFile!.name : 'No file selected',
                  style: TextStyle(fontSize: 16.0),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _saveNews,
                  child: Text('Save News'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
