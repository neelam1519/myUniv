import 'dart:async';
import 'dart:io';

import 'package:findany_flutter/Firebase/storage.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class DisplayMaterials extends StatefulWidget {
  final String path;
  final String unit;
  DisplayMaterials({required this.path, required this.unit});

  @override
  _DisplayMaterialsState createState() => _DisplayMaterialsState();
}

class _DisplayMaterialsState extends State<DisplayMaterials> {
  FirebaseStorageHelper firebaseStorageHelper = FirebaseStorageHelper();
  LoadingDialog loadingDialog = new LoadingDialog();
  Utils utils = new Utils();
  int _currentIndex = 0;
  String storagePath = '';
  List<String> pdfFileNames = [];
  bool isDownloading = false;
  bool stopDownload = false;
  List<File> downloadedFiles = [];
  late StreamController<List<File>> _streamController;

  String appBarText = 'PDFs';

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<File>>();
    storagePath = '${widget.path}/${widget.unit}';
    initialize().then((_) {
      downloadFiles();
    });
  }

  @override
  void dispose() {
    stopDownload = true;
    _streamController.close();
    super.dispose();
  }

  Future<void> initialize() async {
    pdfFileNames = await firebaseStorageHelper.getFileNames(storagePath);
    print('File Names: $pdfFileNames');
  }

  Future<void> downloadFiles() async {
    print('Entered downloadFiles');
    Directory cacheDir = await getTemporaryDirectory();
    String cachePath = '${cacheDir.path}/${storagePath.replaceAll(' ', '')}';

    setState(() {
      isDownloading = true;
      stopDownload = false;
    });

    downloadedFiles.clear();

    for (String fileName in pdfFileNames) {
      if (stopDownload) break;
      File file = File('$cachePath/${fileName.replaceAll(' ', '')}');
      print('Download Cache: ${file.path}');

      if (!file.existsSync()) {
        await firebaseStorageHelper.downloadFile('$storagePath/$fileName').then((downloadedFile) {
          if (downloadedFile != null) {
            setState(() {
              downloadedFiles.add(downloadedFile);
              _streamController.add(downloadedFiles.toList());
            });
          }
        });
      } else {
        print('File already exists');
        setState(() {
          downloadedFiles.add(file);
          _streamController.add(downloadedFiles.toList());
        });
      }
    }
    setState(() {
      isDownloading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarText),
      ),
      body: StreamBuilder<List<File>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          print("Entered Stream");
          if (pdfFileNames.isEmpty) {
            print('Snapshot is empty');
            return Center(
              child: Text('No files available.'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('Connection is waiting');
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            print('Snapshot is empty');
            return Center(
              child: Text('No files available.'),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(snapshot.data![index].path.split('/').last),
                  onTap: () {
                    utils.openFile(snapshot.data![index].path);
                  },
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) async {
          loadingDialog.showDefaultLoading('');
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            appBarText = 'PDFs';
            storagePath = '${widget.path}/${widget.unit}';
            print('Storage Path: $storagePath');
            loadingDialog.dismiss();
          } else if (index == 1) {
            appBarText = 'QUESTION PAPERS';
            storagePath = '${widget.path}/QUESTION PAPERS';
            print('Storage Path: $storagePath');
            loadingDialog.dismiss();
          }
          stopDownload = true;

          await initialize().then((_) async {
            await downloadFiles();
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
    );
  }
}
