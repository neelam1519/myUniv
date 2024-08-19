import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../Firebase/storage.dart';
import '../services/sendnotification.dart';
import '../utils/LoadingDialog.dart';
import '../utils/utils.dart';

class DisplayMaterialsProvider extends ChangeNotifier {
  final FirebaseStorageHelper firebaseStorageHelper;
  final LoadingDialog loadingDialog;
  final NotificationService notificationService;
  final Utils utils;

  DisplayMaterialsProvider({
    required this.firebaseStorageHelper,
    required this.loadingDialog,
    required this.notificationService,
    required this.utils,
  });

  StreamController<List<File>> streamController = StreamController<List<File>>.broadcast();
  int currentIndex = 0;
  String storagePath = '';
  List<String> pdfFileNames = [];
  bool isDownloading = false;
  bool stopDownload = false;
  List<File> downloadedFiles = [];
  String appBarText = 'PDFs';
  bool isInitialized = false;
  String? currentDownloadingFile;
  bool firstDownloadCompleted = false;

  Future<void> initialize(String path, String unit) async {
    if (path.isNotEmpty && unit.isNotEmpty) {
      storagePath = "$path/$unit";
    }
    print("Initialization Path: $storagePath");
    pdfFileNames = await firebaseStorageHelper.getFileNames(storagePath);
    isInitialized = true;
    notifyListeners();
    if (pdfFileNames.isNotEmpty) {
      print("PdfFile List:$pdfFileNames");
      downloadNextFile();
    } else {
      print("Pdf File Names are empty");
      downloadedFiles.clear();
      isDownloading = false;
      loadingDialog.dismiss();
      notifyListeners();
    }
  }

  void clearScreenData() {
    downloadedFiles.clear();
    streamController.add([]);
    currentDownloadingFile = null;
    isDownloading = false;
    firstDownloadCompleted = false;
    stopDownload = true;
    notifyListeners();
  }

  void setStoragePath(String path) {
    storagePath = path;
    print("setStoragePath: $storagePath");
    notifyListeners();
  }

  Future<void> downloadNextFile() async {
    if (pdfFileNames.isEmpty) {
      isDownloading = false;
      loadingDialog.dismiss();
      notifyListeners();
      return;
    }

    Directory cacheDir = await getTemporaryDirectory();
    String cachePath = '${cacheDir.path}/${storagePath.replaceAll(' ', '')}/$appBarText';

    if (stopDownload) {
      print("Download Stopped");
      isDownloading = false;
      loadingDialog.dismiss();
      notifyListeners();
      return;
    }

    isDownloading = true;
    currentDownloadingFile = pdfFileNames.first;
    notifyListeners();

    File file = File('$cachePath/${currentDownloadingFile!.replaceAll(' ', '')}');

    print("File: ${file.path}");

    if (file.existsSync()) {
      print("File already exists, skipping download.");
      downloadedFiles.add(file);
      streamController.add(downloadedFiles.toList());
      pdfFileNames.removeAt(0);
      currentDownloadingFile = pdfFileNames.isNotEmpty ? pdfFileNames.first : null;

      if (!firstDownloadCompleted) {
        firstDownloadCompleted = true;
        loadingDialog.dismiss(); // Stop the loading dialog after the first download
      }

      notifyListeners();
      downloadNextFile(); // Ensure continuation of the download process
    } else {
      await firebaseStorageHelper.downloadFile('$storagePath/$currentDownloadingFile', cachePath).then((downloadedFile) {
        if (downloadedFile != null) {
          downloadedFiles.add(downloadedFile);
          streamController.add(downloadedFiles.toList());
          pdfFileNames.removeAt(0);
          currentDownloadingFile = pdfFileNames.isNotEmpty ? pdfFileNames.first : null;

          if (!firstDownloadCompleted) {
            firstDownloadCompleted = true;
            loadingDialog.dismiss(); // Stop the loading dialog after the first download
          }

          notifyListeners();
          downloadNextFile(); // Ensure continuation of the download process
        }
      });
    }
  }

  Future<void> updateIndex(int index, String path, String unit) async {
    print("UpdateIndex Provider: $index  $path/$unit");
    loadingDialog.showDefaultLoading('Loading files...');
    currentIndex = index;
    stopDownload = true; // Stop any ongoing downloads before changing tabs
    clearScreenData(); // Clear existing data

    if (index == 0) {
      appBarText = 'PDFs';
      storagePath = '$path/$unit';
    } else if (index == 1) {
      appBarText = 'QUESTION PAPERS';
      storagePath = '$path/QUESTION PAPERS';
    }
    stopDownload = false;
    await initialize("", ""); // Re-initialize with new storage path
  }

  Future<void> uploadFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null && result.files.isNotEmpty) {
      loadingDialog.showDefaultLoading('Uploading Files...');
      for (PlatformFile platformFile in result.files) {
        String fileName = platformFile.name;
        String fileExtension = fileName.split('.').last;

        String path = 'userUploadedMaterials/"${storagePath.replaceAll('/', '-')}-${storagePath.split('/')[1]}"/${utils.getTodayDate().replaceAll('/', '-')}';
        File file = File(platformFile.path!);
        await firebaseStorageHelper.uploadFile(
            file, path, '${await utils.getCurrentUserEmail()}-$fileName.$fileExtension');

        DocumentReference specificRef = FirebaseFirestore.instance.doc('AdminDetails/Materials');
        List<String> tokens = await utils.getSpecificTokens(specificRef);
        notificationService.sendNotification(
            tokens, "Materials", '${result.count} files uploaded by ${await utils.getCurrentUserEmail()}', {});

        utils.showToastMessage('Files are submitted sent for reviewing');
        loadingDialog.dismiss();
      }
    } else {
      utils.showToastMessage('No files are selected');
    }
  }

  @override
  void dispose() {
    stopDownload = true;
    streamController.close();
    loadingDialog.dismiss();
    super.dispose();
  }
}
