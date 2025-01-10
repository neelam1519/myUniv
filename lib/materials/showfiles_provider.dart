import 'package:dio/dio.dart';
import 'package:findany_flutter/services/pdfscreen.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class ShowFilesProvider with ChangeNotifier {
  Utils utils = Utils();
  LoadingDialog loadingDialog = LoadingDialog();
  String _selectedValue = 'YEAR 1';
  final Map<String, String> _selectedFiles = {};
  Map<String, String> retrievedFiles = {};
  Icon addIcon = const Icon(Icons.add);
  Icon minusIcon = const Icon(Icons.remove);
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;

  String get selectedValue => _selectedValue;
  Map<String, String> get selectedFiles => _selectedFiles;
  Map<String, String> get files => retrievedFiles;
  bool get searching => isSearching;

  ShowFilesProvider() {
    fetchFiles();
  }

  void setSelectedValue(String newValue) {
    _selectedValue = newValue;
    fetchFiles();
    notifyListeners();
  }

  void toggleSearching() {
    isSearching = !isSearching;
    notifyListeners();
  }

  void addFile(String filename, String url) {
    _selectedFiles[filename] = url;
    utils.showToastMessage('$filename added to your xerox list');
    notifyListeners();
  }

  void removeFile(String filename) {
    _selectedFiles.remove(filename);
    utils.showToastMessage('$filename removed from your xerox list');
    notifyListeners();
  }

  Future<void> fetchFiles() async {
    loadingDialog.showDefaultLoading('Getting Files...');
    try {
      final ListResult result = await FirebaseStorage.instance.ref().child('ShowFiles/$_selectedValue').listAll();
      retrievedFiles.clear();
      for (final ref in result.items) {
        String url = await ref.getDownloadURL();
        retrievedFiles[ref.name] = url;
      }
      EasyLoading.dismiss();
      notifyListeners();
    } catch (e) {
      EasyLoading.dismiss();
      throw e.toString();
    }
  }

  Future<void> downloadAndStoreFile(String firebaseUrl, String fileName) async {
    final cacheDir = await getTemporaryDirectory();
    final uploadDir = Directory('${cacheDir.path}/xeroxPdfs');

    try {
      if (!await uploadDir.exists()) {
        await uploadDir.create(recursive: true);
      }

      final filePath = '${uploadDir.path}/$fileName';
      final response = await http.get(Uri.parse(firebaseUrl));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        _selectedFiles[fileName] = filePath;
      } else {
        print('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading file: $e');
    }
  }

  Future<void> downloadAndOpenFile(String url, String filename, BuildContext context) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/FileSelection/$filename';
    final file = File(filePath);

    try {
      if (await file.exists()) {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => PDFScreen(filePath: filePath, title: filename),
        //   ),
        // );
      } else {
        loadingDialog.showDefaultLoading('Downloading...');
        final dio = Dio();

        await dio.download(url, filePath, onReceiveProgress: (received, total) {
          if (total != -1) {
            EasyLoading.showProgress(received / total, status: 'Downloading...');
          }
        });

        EasyLoading.dismiss();
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => PDFScreen(filePath: filePath, title: filename),
        //   ),
        // );
      }
    } catch (e) {
      EasyLoading.dismiss();
      print('Error downloading or opening file: $e');
    }
  }

  @override
  void dispose() {
    utils.clearCache();
    loadingDialog.dismiss();
    searchController.dispose();
    super.dispose();
  }
}
