import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Firebase/firestore.dart';
import '../Firebase/realtimedatabase.dart';
import '../Firebase/storage.dart';
import '../services/sendnotification.dart';
import '../utils/LoadingDialog.dart';
import '../utils/utils.dart';

class AddNotificationProvider with ChangeNotifier {
  final FirebaseStorageHelper _firebaseStorageHelper = FirebaseStorageHelper();
  final FireStoreService _fireStoreService = FireStoreService();
  final RealTimeDatabase _realTimeDatabase = RealTimeDatabase();
  final Utils _utils = Utils();
  final LoadingDialog _loadingDialog = LoadingDialog();
  final NotificationService _notificationService = NotificationService();

  TextEditingController _titleController = TextEditingController();
  TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Getters
  TextEditingController get titleController => _titleController;
  TextEditingController get messageController => _messageController;
  GlobalKey<FormState> get formKey => _formKey;

  // Setters
  set titleController(TextEditingController controller) {
    _titleController.dispose();
    _titleController = controller;
    notifyListeners();
  }

  set messageController(TextEditingController controller) {
    _messageController.dispose();
    _messageController = controller;
    notifyListeners();
  }

  Future<void> saveNotification(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      _loadingDialog.showDefaultLoading('Sending Notification');
      final String title = _titleController.text;
      final String message = _messageController.text;

      try {
        final int? count = await _realTimeDatabase.incrementValue('notification');
        if (count != null) {
          final Map<String, String> data = {'title': title, 'message': message};
          final DocumentReference documentReference = FirebaseFirestore.instance.doc('notifications/$count');
          await _fireStoreService.uploadMapDataToFirestore(data, documentReference);

          final List<String> tokens = await _utils.getAllTokens();
          await _notificationService.sendNotification(tokens, title, message, {"source": "NotificationHome"});

          _titleController.clear();
          _messageController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification Sent')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send notification: $e')),
        );
      } finally {
        _loadingDialog.dismiss();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _loadingDialog.dismiss();
    super.dispose();
  }
}
