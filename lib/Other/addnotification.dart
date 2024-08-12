// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:findany_flutter/Firebase/firestore.dart';
// import 'package:findany_flutter/Firebase/realtimedatabase.dart';
// import 'package:findany_flutter/Firebase/storage.dart';
// import 'package:findany_flutter/services/sendnotification.dart';
// import 'package:findany_flutter/utils/LoadingDialog.dart';
// import 'package:findany_flutter/utils/utils.dart';
// import 'package:flutter/material.dart';
//
// class AddNotification extends StatefulWidget {
//   const AddNotification({super.key});
//
//   @override
//   _AddNotificationState createState() => _AddNotificationState();
// }
//
// class _AddNotificationState extends State<AddNotification> {
//   final FirebaseStorageHelper _firebaseStorageHelper = FirebaseStorageHelper();
//   final FireStoreService _fireStoreService = FireStoreService();
//   final RealTimeDatabase _realTimeDatabase = RealTimeDatabase();
//   final Utils _utils = Utils();
//   final LoadingDialog _loadingDialog = LoadingDialog();
//   final NotificationService _notificationService = NotificationService();
//
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _messageController = TextEditingController();
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//
//   Future<void> _saveNotification() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       _loadingDialog.showDefaultLoading('Sending Notification');
//       final String title = _titleController.text;
//       final String message = _messageController.text;
//
//       try {
//         final int? count = await _realTimeDatabase.incrementValue('notification');
//         if (count != null) {
//           final Map<String, String> data = {'title': title, 'message': message};
//           final DocumentReference documentReference = FirebaseFirestore.instance.doc('notifications/$count');
//           await _fireStoreService.uploadMapDataToFirestore(data, documentReference);
//
//           final List<String> tokens = await _utils.getAllTokens();
//           await _notificationService.sendNotification(tokens, title, message, {"source": "NotificationHome"});
//
//           _titleController.clear();
//           _messageController.clear();
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Notification Sent')),
//           );
//           Navigator.pop(context);
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to send notification: $e')),
//         );
//       } finally {
//         _loadingDialog.dismiss();
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _titleController.dispose();
//     _messageController.dispose();
//     _loadingDialog.dismiss();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notification'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: <Widget>[
//               SizedBox(
//                 height: 60,
//                 child: TextFormField(
//                   controller: _titleController,
//                   decoration: const InputDecoration(labelText: 'Title'),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a title';
//                     }
//                     return null;
//                   },
//                 ),
//               ),
//               const SizedBox(height: 16),
//               SizedBox(
//                 height: 180,
//                 child: TextFormField(
//                   controller: _messageController,
//                   decoration: const InputDecoration(labelText: 'Message'),
//                   maxLines: null,
//                   expands: true,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a message';
//                     }
//                     return null;
//                   },
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: _saveNotification,
//                 child: const Text('Send Notification'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:findany_flutter/provider/addnotification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddNotification extends StatefulWidget {
  const AddNotification({super.key});

  @override
  State<AddNotification> createState() => _AddNotificationState();
}

class _AddNotificationState extends State<AddNotification> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AddNotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notification'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: notificationProvider.formKey,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 60,
                    child: TextFormField(
                      controller: notificationProvider.titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: TextFormField(
                      controller: notificationProvider.messageController,
                      decoration: const InputDecoration(labelText: 'Message'),
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => notificationProvider.saveNotification,
                    child: const Text('Send Notification'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
