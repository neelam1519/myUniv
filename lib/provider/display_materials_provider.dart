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
  bool isDownloading = true;
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

    Directory cacheDir = await getTemporaryDirectory();
    String cachePath = '${cacheDir.path}/${storagePath.replaceAll(' ', '')}/$appBarText';

    print("Cache Path: $cachePath");
    await getCachedPDFFiles(cachePath);

    if (await utils.checkInternetConnection()) {
      pdfFileNames = await firebaseStorageHelper.getFileNames(storagePath);
      isInitialized = true;
      notifyListeners();
      loadingDialog.dismiss();
      downloadMissingFiles();
    } else {
      print("No internet connection, using cached files");
      utils.showToastMessage('No internet connection. Showing cached files.');
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> getCachedPDFFiles(String cachePath) async {
    Directory cacheDir = Directory(cachePath);

    if (cacheDir.existsSync()) {
      List<FileSystemEntity> files = cacheDir.listSync();

      for (var file in files) {
        if (file is File && file.path.endsWith('.pdf')) {
          downloadedFiles.add(file);
        }
      }
    }
    print("Cached Files: $downloadedFiles");
    streamController.add(downloadedFiles.toList());
  }

  Future<void> downloadMissingFiles() async {
    int totalFiles = pdfFileNames.length;
    int downloadedCount = 0;

    // Extract the filenames from the downloadedFiles list
    List<String> downloadedFileNames = downloadedFiles.map((file) {
      return file.path.split('/').last.replaceAll(' ', '');
    }).toList();



    for (var fileName in pdfFileNames) {
      if (stopDownload) break;

      // Clean up the fileName to match the format used in the downloadedFileNames list
      String cleanedFileName = fileName.replaceAll(' ', '');

      // Check if the file is already downloaded
      if (!downloadedFileNames.contains(cleanedFileName)) {
        Directory cacheDir = await getTemporaryDirectory();
        String cachePath = '${cacheDir.path}/${storagePath.replaceAll(' ', '')}/$appBarText';
        File file = File('$cachePath/$cleanedFileName');

        if (!file.existsSync()) {
          await firebaseStorageHelper.downloadFile('$storagePath/$fileName', cachePath).then((downloadedFile) {
            if (downloadedFile != null) {
              print("Downloading File: $fileName");

              downloadedFiles.add(downloadedFile);
              streamController.add(downloadedFiles.toList()); // Show the downloaded file immediately
              notifyListeners(); // Notify listeners to update the UI
            }
          });
        }
      }

      downloadedCount++;

      // If all files have been downloaded, show a toast message
      if (downloadedCount == totalFiles) {
        utils.showToastMessage('All files have been downloaded successfully.');
      }
    }
    isDownloading = false;
    notifyListeners();
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

  Future<void> updateIndex(int index, String path, String unit) async {
    print("UpdateIndex Provider: $index  $path/$unit");

    // Stop ongoing downloads and clear data
    stopDownload = true; // Stop any ongoing downloads
    clearScreenData(); // Clear existing data

    // Update the current index and app bar text based on the new index
    currentIndex = index;
    if (index == 0) {
      appBarText = 'PDFs';
      storagePath = '$path/$unit';
    } else if (index == 1) {
      appBarText = 'QUESTION PAPERS';
      storagePath = '$path/QUESTION PAPERS';
    }

    stopDownload = false; // Allow downloads to start again
    loadingDialog.showDefaultLoading('Loading files...');

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
