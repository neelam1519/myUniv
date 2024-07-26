import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/Firebase/storage.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:universal_io/io.dart';
import '../services/pdfscreen.dart';

class DisplayMaterials extends StatefulWidget {
  final String path;
  final String unit;
  final String subject;

  DisplayMaterials({required this.path, required this.subject, required this.unit});

  @override
  _DisplayMaterialsState createState() => _DisplayMaterialsState();
}

class _DisplayMaterialsState extends State<DisplayMaterials> {
  FirebaseStorageHelper firebaseStorageHelper = FirebaseStorageHelper();
  LoadingDialog loadingDialog = LoadingDialog();
  NotificationService notificationService = NotificationService();
  Utils utils = Utils();

  int _currentIndex = 0;
  String storagePath = '';
  List<String> pdfFileNames = [];
  bool isDownloading = false;
  bool stopDownload = false;
  List<File> downloadedFiles = [];
  late StreamController<List<File>> _streamController;
  String appBarText = 'PDFs';
  bool isInitialized = false;
  String? currentDownloadingFile;
  bool firstDownloadCompleted = false;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<File>>();
    storagePath = '${widget.path}/${widget.unit}';
    initialize().then((_) {
      setState(() {
        isInitialized = true;
        if (pdfFileNames.isNotEmpty) {
          downloadNextFile();
        } else {
          loadingDialog.dismiss();
        }
      });
    });
    loadingDialog.showDefaultLoading('Loading Files...');
  }

  @override
  void dispose() {
    stopDownload = true;
    _streamController.close();
    loadingDialog.dismiss();
    super.dispose();
  }

  Future<void> initialize() async {
    pdfFileNames = await firebaseStorageHelper.getFileNames(storagePath);
  }

  Future<void> downloadNextFile() async {
    if (pdfFileNames.isEmpty) {
      setState(() {
        isDownloading = false;
        loadingDialog.dismiss();
      });
      return;
    }

    Directory cacheDir = await getTemporaryDirectory();
    String cachePath = '${cacheDir.path}/${storagePath.replaceAll(' ', '')}';

    if (stopDownload) {
      setState(() {
        isDownloading = false;
        loadingDialog.dismiss();
      });
      return;
    }

    setState(() {
      isDownloading = true;
      currentDownloadingFile = pdfFileNames.first;
    });

    File file = File('$cachePath/${currentDownloadingFile!.replaceAll(' ', '')}');

    if (!file.existsSync()) {
      await firebaseStorageHelper.downloadFile('$storagePath/$currentDownloadingFile').then((downloadedFile) {
        if (downloadedFile != null) {
          setState(() {
            downloadedFiles.add(downloadedFile);
            _streamController.add(downloadedFiles.toList());
            pdfFileNames.removeAt(0);
            currentDownloadingFile = pdfFileNames.isNotEmpty ? pdfFileNames.first : null;
            if (!firstDownloadCompleted) {
              firstDownloadCompleted = true;
              loadingDialog.dismiss(); // Stop the loading dialog after the first download
            }
          });
        }
      });
    } else {
      setState(() {
        downloadedFiles.add(file);
        _streamController.add(downloadedFiles.toList());
        pdfFileNames.removeAt(0);
        currentDownloadingFile = pdfFileNames.isNotEmpty ? pdfFileNames.first : null;
        if (!firstDownloadCompleted) {
          firstDownloadCompleted = true;
          loadingDialog.dismiss(); // Stop the loading dialog after the first download
        }
      });
    }

    if (pdfFileNames.isNotEmpty) {
      downloadNextFile();
    } else {
      setState(() {
        isDownloading = false;
        if (!firstDownloadCompleted) {
          firstDownloadCompleted = true;
          loadingDialog.dismiss();
        }
      });
    }
  }

  Widget buildSkeletonView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 4, // Display 4 shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            elevation: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(color: Colors.grey[300]),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 20,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text("${widget.subject}>${widget.unit}"),
        ),
      ),
      body: StreamBuilder<List<File>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (!isInitialized) {
            return buildSkeletonView();
          } else if (isDownloading && !firstDownloadCompleted) {
            return buildSkeletonView();
          } else if (snapshot.hasError) {
            loadingDialog.dismiss();
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!isDownloading && (snapshot.data == null || snapshot.data!.isEmpty)) {
            loadingDialog.dismiss();
            return Center(
              child: Text('No files available.'),
            );
          } else {
            List<File> filesToShow = snapshot.data!;
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filesToShow.length,
              itemBuilder: (context, index) {
                File pdfFile = filesToShow[index];
                return GestureDetector(
                  onTap: () {
                    viewPdfFullScreen(pdfFile.path, pdfFile.path.split('/').last);
                  },
                  child: Card(
                    elevation: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: PDFView(
                            filePath: pdfFile.path,
                            enableSwipe: true,
                            swipeHorizontal: false,
                            autoSpacing: false,
                            pageFling: false,
                            onRender: (pages) {
                              setState(() {});
                            },
                            onError: (error) {
                              print(error.toString());
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            pdfFile.path.split('/').last,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) async {
          loadingDialog.showDefaultLoading('Loading files...');
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            appBarText = 'PDFs';
            storagePath = '${widget.path}/${widget.unit}';
          } else if (index == 1) {
            appBarText = 'QUESTION PAPERS';
            storagePath = '${widget.path}/QUESTION PAPERS';
          }
          stopDownload = true;
          await initialize().then((_) {
            downloadNextFile();
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'PDFs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pages),
            label: 'QUESTION PAPERS',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

          if (result != null && result.files.isNotEmpty) {
            loadingDialog.showDefaultLoading('Uploading Files...');
            for (PlatformFile platformFile in result.files) {
              String fileName = platformFile.name;
              String fileExtension = fileName.split('.').last;

              print("Filename: $fileName");
              print("Extension: $fileExtension");

              String path = 'userUploadedMaterials/"${widget.path.replaceAll('/', '-')}-${widget.unit}"/${utils.getTodayDate().replaceAll('/', '-')}';
              File file = File(platformFile.path!);
              await firebaseStorageHelper.uploadFile(file, path, '${await utils.getCurrentUserEmail()}-$fileName.$fileExtension');

              DocumentReference specificRef = FirebaseFirestore.instance.doc('AdminDetails/Materials');
              List<String> tokens = await utils.getSpecificTokens(specificRef);
              notificationService.sendNotification(tokens, "Materials", '${result.count} files uploaded by ${await utils.getCurrentUserEmail()}', {});

              utils.showToastMessage('Files are submitted sent for reviewing', context);
              loadingDialog.dismiss();
            }
          } else {
            utils.showToastMessage('No files are selected', context);
            print('No files selected');
          }
        },
        child: Icon(Icons.upload),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void viewPdfFullScreen(String? filePath, String title) {
    if (filePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFScreen(filePath: filePath, title: title),
        ),
      );
    }
  }
}
