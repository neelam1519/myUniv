import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/Firebase/storage.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AddNotification extends StatefulWidget {
  @override
  _AddNotificationState createState() => _AddNotificationState();
}

class _AddNotificationState extends State<AddNotification> {

  FirebaseStorageHelper firebaseStorageHelper = FirebaseStorageHelper();
  FireStoreService fireStoreService = FireStoreService();
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();
  Utils utils = Utils();
  LoadingDialog loadingDialog = LoadingDialog();
  NotificationService notificationService = NotificationService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _saveNotification() async{
    if (_formKey.currentState?.validate() ?? false) {
      loadingDialog.showDefaultLoading('Sending Notification');
      final String title = _titleController.text;
      final String message = _messageController.text;

      print('Title: $title, Message: $message');

      int? count = await realTimeDatabase.incrementValue('notification');
      Map<String,String> data= {'title':title,'message':message};
      DocumentReference documentReference = FirebaseFirestore.instance.doc('notifications/${count.toString()}');
      fireStoreService.uploadMapDataToFirestore(data, documentReference);

      DocumentReference specificRef = FirebaseFirestore.instance.doc('AdminDetails/Notification');
      List<String> tokens = await utils.getSpecificTokens(specificRef);
      notificationService.sendNotification(tokens, "Notification", title, {"source":"NotificationHome"});

      _titleController.clear();
      _messageController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification saved')),
      );

      Navigator.pop(context);
    }
    loadingDialog.dismiss();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    loadingDialog.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Notification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Container(
                height: 60,
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),
              Container(
                height: 180, // Approximately three times the height of the title field
                child: TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(labelText: 'Message'),
                  maxLines: null,
                  expands: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a message';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveNotification,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
