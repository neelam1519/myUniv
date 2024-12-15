import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import '../Firebase/firestore.dart';
import '../Firebase/realtimedatabase.dart';
import '../utils/LoadingDialog.dart';
import '../utils/utils.dart';

class CreateGroupChatProvider with ChangeNotifier {
  final RealTimeDatabase realTimeDatabase = RealTimeDatabase();
  final FireStoreService fireStoreService = FireStoreService();
  final Utils utils = Utils();
  final LoadingDialog loadingDialog = LoadingDialog();

  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupReasonController = TextEditingController();
  String _selectedMessagePermission = 'Admins';
  String _downloadUrl = '';

  TextEditingController get groupNameController => _groupNameController;
  TextEditingController get groupReasonController => _groupReasonController;
  String get selectedMessagePermission => _selectedMessagePermission;
  String get downloadUrl => _downloadUrl;

  set selectedMessagePermission(String value) {
    _selectedMessagePermission = value;
    notifyListeners();
  }

  set downloadUrl(String value) {
    _downloadUrl = value;
    notifyListeners();
  }

  Future<String?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      if (result != null && result.paths.isNotEmpty) {
        return result.paths[0];
      }
    } catch (e) {
      print('Error picking file: $e');
    }
    return null;
  }

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImageAndStoreUrl(String? imagePath) async {
    loadingDialog.showDefaultLoading('Updating profile');
    try {
      if (imagePath != null) {
        String extension = utils.getFileExtension(File(imagePath));
        Reference ref = _storage.ref().child('ProfileImages').child('${utils.getCurrentUserUID()}.$extension');
        final UploadTask uploadTask = ref.putFile(File(imagePath));
        final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        loadingDialog.dismiss();
        this.downloadUrl = downloadUrl;
        return downloadUrl;
      }
    } catch (e) {
      print('Error uploading file and storing URL: $e');
      loadingDialog.dismiss();
    }
    loadingDialog.dismiss();
    return null;
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupReasonController.dispose();
    super.dispose();
  }
}
