import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';

class Review extends StatefulWidget {
  @override
  _ReviewState createState() => _ReviewState();
}

class _ReviewState extends State<Review> {

  Utils utils = new Utils();
  RealTimeDatabase realTimeDatabase = new RealTimeDatabase();
  FireStoreService fireStoreService = new FireStoreService();
  LoadingDialog loadingDialog = new LoadingDialog();

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
              onPressed: () async{
                loadingDialog.showDefaultLoading('Submitting Review');
                String reviewText = _controller.text;

                int? id = await realTimeDatabase.incrementValue('Reviews');

                Map<String,dynamic> reviewMap = {id.toString():reviewText};
                DocumentReference reviewRef = FirebaseFirestore.instance.doc('/Reviews/${utils.getTodayDate()}');
                fireStoreService.uploadMapDataToFirestore(reviewMap, reviewRef);

                loadingDialog.dismiss();
                utils.showToastMessage('Review submitted', context);
                Navigator.pop(context);
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
