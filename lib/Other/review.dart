import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/main.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';

class Review extends StatefulWidget {
  @override
  _ReviewState createState() => _ReviewState();
}

class _ReviewState extends State<Review> {
  Utils utils = Utils();
  RealTimeDatabase realTimeDatabase = RealTimeDatabase();
  FireStoreService fireStoreService = FireStoreService();
  LoadingDialog loadingDialog = LoadingDialog();
  NotificationService notificationService = new NotificationService();

  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Write your review',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter your review here',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {

                if(_controller.text.isEmpty){
                  utils.showToastMessage('Enter the text in the box', context);
                  return;
                }
                loadingDialog.showDefaultLoading('Submitting Review');
                String reviewText = _controller.text;

                int? id = await realTimeDatabase.incrementValue('Reviews');

                Map<String, dynamic> reviewMap = {
                  '${id.toString()}(${await utils.getCurrentUserEmail()})': reviewText
                };
                DocumentReference reviewRef = FirebaseFirestore.instance.doc('/Reviews/${utils.getTodayDate().replaceAll('/', '-')}');
                fireStoreService.uploadMapDataToFirestore(reviewMap, reviewRef);

                DocumentReference reviewAdminRef = FirebaseFirestore.instance.doc('AdminDetails/Reviews');
                List<String> tokens = await utils.getSpecificTokens(reviewAdminRef);
                notificationService.sendNotification(tokens, 'Review', reviewText, {});

                loadingDialog.dismiss();
                utils.showToastMessage('Review submitted', context);
                Navigator.pop(context);
              },
              child: Text('Submit'),
            ),
            SizedBox(height: 20.0),
            Text(
              'Contact Us: neelammsr@gmail.com',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    loadingDialog.dismiss();
    super.dispose();
  }
}
