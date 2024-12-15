// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:findany_flutter/Firebase/firestore.dart';
// import 'package:findany_flutter/Firebase/realtimedatabase.dart';
// import 'package:findany_flutter/services/sendnotification.dart';
// import 'package:findany_flutter/utils/LoadingDialog.dart';
// import 'package:findany_flutter/utils/utils.dart';
// import 'package:flutter/material.dart';
//
// class Review extends StatefulWidget {
//   const Review({super.key});
//
//   @override
//   _ReviewState createState() => _ReviewState();
// }
//
// class _ReviewState extends State<Review> {
//   Utils utils = Utils();
//   RealTimeDatabase realTimeDatabase = RealTimeDatabase();
//   FireStoreService fireStoreService = FireStoreService();
//   LoadingDialog loadingDialog = LoadingDialog();
//   NotificationService notificationService = NotificationService();
//
//   final TextEditingController _controller = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Review/Suggestions'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               'Write your review/suggestion',
//               style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20.0),
//             TextField(
//               controller: _controller,
//               decoration: const InputDecoration(
//                 hintText: 'Enter your review/suggestion here',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 5,
//             ),
//             const SizedBox(height: 20.0),
//             ElevatedButton(
//               onPressed: () async {
//
//                 if(_controller.text.isEmpty){
//                   utils.showToastMessage('Enter the text in the box',);
//                   return;
//                 }
//                 loadingDialog.showDefaultLoading('Submitting Review');
//                 String reviewText = _controller.text;
//
//                 int? id = await realTimeDatabase.incrementValue('Reviews');
//
//                 Map<String, dynamic> reviewMap = {
//                   '${id.toString()}(${await utils.getCurrentUserEmail()})': reviewText
//                 };
//                 DocumentReference reviewRef = FirebaseFirestore.instance.doc('/Reviews/${utils.getTodayDate().replaceAll('/', '-')}');
//                 fireStoreService.uploadMapDataToFirestore(reviewMap, reviewRef);
//
//                 DocumentReference reviewAdminRef = FirebaseFirestore.instance.doc('AdminDetails/Reviews');
//                 List<String> tokens = await utils.getSpecificTokens(reviewAdminRef);
//                 notificationService.sendNotification(tokens, 'Review', reviewText, {});
//
//                 loadingDialog.dismiss();
//                 utils.showToastMessage('Review submitted');
//                 Navigator.pop(context);
//               },
//               child: const Text('Submit'),
//             ),
//             const SizedBox(height: 20.0),
//             const Text(
//               'Contact Us: findanylive@gmail.com',
//               style: TextStyle(fontSize: 16.0),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     loadingDialog.dismiss();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'review_provider.dart';

class Review extends StatelessWidget {
  const Review({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReviewProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review/Suggestions'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Consumer<ReviewProvider>(
            builder: (context, reviewProvider, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Write your review/suggestion',
                    style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20.0),
                  TextField(
                    controller: reviewProvider.controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter your review/suggestion here',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: () async {
                      await reviewProvider.submitReview(context);
                    },
                    child: const Text('Submit'),
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Contact Us: findanylive@gmail.com',
                    style: TextStyle(fontSize: 16.0),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

