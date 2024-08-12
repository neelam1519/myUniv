// import 'dart:io';
// import 'package:findany_flutter/Firebase/firestore.dart';
// import 'package:findany_flutter/Firebase/realtimedatabase.dart';
// import 'package:findany_flutter/services/sendnotification.dart';
// import 'package:findany_flutter/utils/utils.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path/path.dart' as path;
//
// class AddNews extends StatefulWidget {
//   final String title;
//   final String summary;
//   final String details;
//   final String? pdfUrl;
//   final String documentID;
//
//   const AddNews({super.key, required this.title, required this.summary, required this.details, this.pdfUrl, required this.documentID});
//
//   @override
//   State<AddNews> createState() => _AddNewsState();
// }
//
// class _AddNewsState extends State<AddNews>{
//   RealTimeDatabase realTimeDatabase = RealTimeDatabase();
//   FireStoreService fireStoreService = FireStoreService();
//   Utils utils = Utils();
//   NotificationService notificationService = NotificationService();
//
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _titleController;
//   late TextEditingController _summaryController;
//   late TextEditingController _detailsController;
//   PlatformFile? pickedFile;
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _titleController = TextEditingController(text: widget.title);
//     _summaryController = TextEditingController(text: widget.summary);
//     _detailsController = TextEditingController(text: widget.details);
//   }
//
//   @override
//   void dispose() {
//     _titleController.dispose();
//     _summaryController.dispose();
//     _detailsController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickFile() async {
//     final result = await FilePicker.platform.pickFiles();
//     if (result != null) {
//       setState(() {
//         pickedFile = result.files.first;
//       });
//     }
//   }
//
//   Future<String?> _uploadFile() async {
//     if (pickedFile == null) return null;
//     final fileName = path.basename(pickedFile!.path!);
//     final destination = 'news/${utils.getTodayDate().replaceAll('/', '-')}/$fileName';
//
//     try {
//       final ref = FirebaseStorage.instance.ref(destination);
//       await ref.putFile(File(pickedFile!.path!));
//       return await ref.getDownloadURL();
//     } catch (e) {
//       print('Error uploading file: $e');
//       return null;
//     }
//   }
//
//   Future<void> _saveNews() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });
//
//       final pdfUrl = await _uploadFile();
//       int? count =await realTimeDatabase.incrementValue('News');
//       Map<String,dynamic> data = {'title': _titleController.text, 'summary': _summaryController.text, 'details': _detailsController.text,
//         'pdfUrl': pdfUrl, 'timestamp': Timestamp.now()};
//
//       if(widget.documentID.isNotEmpty){
//         DocumentReference documentReference = FirebaseFirestore.instance.doc('/news/${widget.documentID}');
//         fireStoreService.deleteDocument(documentReference);
//       }
//
//       print('News Data: $data');
//       DocumentReference newsRef = FirebaseFirestore.instance.doc('news/${count.toString()}');
//       fireStoreService.uploadMapDataToFirestore(data, newsRef);
//
//       List<String> tokens = await utils.getAllTokens();
//       Map<String,String> additionalData = {'source':'NewsListScreen'};
//       notificationService.sendNotification(tokens, 'University News',_titleController.text,additionalData);
//
//       setState(() {
//         _isLoading = false;
//       });
//
//       Navigator.of(context).pop();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add News'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 TextFormField(
//                   controller: _titleController,
//                   decoration: const InputDecoration(labelText: 'Title'),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a title';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16.0),
//                 TextFormField(
//                   controller: _summaryController,
//                   decoration: const InputDecoration(labelText: 'Summary'),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a summary';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16.0),
//                 TextFormField(
//                   controller: _detailsController,
//                   decoration: const InputDecoration(labelText: 'Details'),
//                   maxLines: 5,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter details';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16.0),
//                 ElevatedButton.icon(
//                   onPressed: _pickFile,
//                   icon: const Icon(Icons.attach_file),
//                   label: const Text('Upload File'),
//                 ),
//                 const SizedBox(height: 8.0),
//                 Text(
//                   pickedFile != null ? pickedFile!.name : 'No file selected',
//                   style: const TextStyle(fontSize: 16.0),
//                 ),
//                 const SizedBox(height: 16.0),
//                 ElevatedButton(
//                   onPressed: _saveNews,
//                   child: const Text('Save News'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/addnews_provider.dart';

class AddNews extends StatefulWidget {
  final String title;
  final String summary;
  final String details;
  final String? pdfUrl;
  final String documentID;

  const AddNews({
    super.key,
    required this.title,
    required this.summary,
    required this.details,
    this.pdfUrl,
    required this.documentID,
  });

  @override
  State<AddNews> createState() => _AddNewsState();
}

class _AddNewsState extends State<AddNews> {
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    final addNewsProvider = Provider.of<AddNewsProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleController = TextEditingController(text: widget.title);
      _summaryController = TextEditingController(text: widget.summary);
      _detailsController = TextEditingController(text: widget.details);

      addNewsProvider.titleController = _titleController;
      addNewsProvider.summaryController = _summaryController;
      addNewsProvider.detailsController = _detailsController;
    });
  }

  @override
  Widget build(BuildContext context) {
    final addNewsProvider = Provider.of<AddNewsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add News'),
      ),
      body: addNewsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: addNewsProvider.formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: addNewsProvider.titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: addNewsProvider.summaryController,
                  decoration: const InputDecoration(labelText: 'Summary'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a summary';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: addNewsProvider.detailsController,
                  decoration: const InputDecoration(labelText: 'Details'),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter details';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton.icon(
                  onPressed: () async {
                    await addNewsProvider.pickFile();
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Upload File'),
                ),
                const SizedBox(height: 8.0),
                Text(
                  addNewsProvider.pickedFile != null
                      ? addNewsProvider.pickedFile!.name
                      : 'No file selected',
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    addNewsProvider.saveNews(widget.documentID, context);
                  },
                  child: const Text('Save News'),
                ),
                if (addNewsProvider.error != null)
                  Text(
                    addNewsProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    final addNewsProvider = Provider.of<AddNewsProvider>(context, listen: false);
    addNewsProvider.disposeControllers();
    super.dispose();
  }
}
