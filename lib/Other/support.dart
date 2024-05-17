import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Support extends StatefulWidget {
  @override
  _SupportState createState() => _SupportState();
}

class _SupportState extends State<Support> {
  LoadingDialog loadingDialog = LoadingDialog();
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();
  FireStoreService fireStoreService = FireStoreService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      loadingDialog.showDefaultLoading('Submitting Form');
      int? id = await realTimeDatabase.incrementValue('Support');

      Map<String, dynamic> reviewMap = {
        'Name': _nameController.text,
        'Email': _emailController.text,
        'Message': _messageController.text
      };

      DocumentReference reviewRef = FirebaseFirestore.instance.doc('/Support/$id');
      fireStoreService.uploadMapDataToFirestore(reviewMap, reviewRef);

      loadingDialog.dismiss();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Form submitted successfully')),
      );

      _nameController.clear();
      _emailController.clear();
      _messageController.clear();

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Support'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(labelText: 'Message'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your message';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit'),
              ),
              SizedBox(height: 10), // Add some space between the button and the phone number
              Text(
                'Contact us at: 8501070702', // Replace with your actual mobile number
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
