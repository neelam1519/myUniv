import 'dart:io';

import 'package:dio/dio.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:findany_flutter/xerox/xeroxhome.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class ShowFiles extends StatefulWidget {

  // final Map<String, String> fileData;
  // ShowFiles({required this.fileData});

  @override
  _ShowFilesState createState() => _ShowFilesState();
}

class _ShowFilesState extends State<ShowFiles> {
  Utils utils = new Utils();
  LoadingDialog loadingDialog = new LoadingDialog();
  String _selectedValue = '1'; // Default selected value
  Map<String, String> _selectedFiles = {}; // List to store selected file names

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xerox Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0), // Adjust the padding value as needed
            child: Row(
              children: [
                Text(
                  'Year',
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
                SizedBox(width: 10), // Add some space between the text and the dropdown
                DropdownButton(
                  value: _selectedValue,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedValue = newValue.toString();
                      // Add your logic here based on the selected value
                    });
                  },
                  items: ['1', '2', '3', '4'].map<DropdownMenuItem<String>>((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.check), // Add tick icon
            onPressed: () {

              Navigator.pop(context, _selectedFiles);

              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(builder: (context) => XeroxHome(fileData: _selectedFiles)),
              // );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: FutureBuilder<Map<String, String>>(
          future: fetchFiles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              Map<String, String> fileUrls = snapshot.data!;
              return ListView.builder(
                itemCount: fileUrls.length,
                itemBuilder: (context, index) {
                  String filename = fileUrls.keys.elementAt(index);
                  String url = fileUrls.values.elementAt(index);
                  bool isSelected = _selectedFiles.containsKey(filename); // Check if file is selected
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 5.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Stack(
                      children: [
                        ListTile(
                          title: Text(filename),
                          onTap: () {
                            _downloadAndOpenFile(url, filename);
                          },
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: isSelected ? Icon(Icons.remove) : Icon(Icons.add), // Change icon based on selection
                            onPressed: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedFiles.remove(filename); // Remove file from selected files
                                } else {
                                  _selectedFiles[filename] = url; // Add file to selected files
                                }
                              }); // Rebuild UI
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _downloadAndOpenFile(String url, String filename) async {
    try {
      loadingDialog.showDefaultLoading('Downloading...'); // Show progress indicator
      final dio = Dio();
      final dir = await getTemporaryDirectory(); // Get temporary directory
      final filePath = '${dir.path}/FileSelection/$filename'; // Create file path

      print('Temp File Path: ${filePath}');

      await dio.download(url, filePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          EasyLoading.showProgress(received / total, status: 'Downloading...'); // Update progress
        }
      });

      EasyLoading.dismiss(); // Dismiss progress indicator
      setState(() {}); // Trigger rebuild to update UI
      await OpenFile.open(filePath); // Open the downloaded file
    } catch (e) {
      EasyLoading.dismiss(); // Dismiss progress indicator in case of error
      print('Error downloading or opening file: $e');
    }
  }

  Future<Map<String, String>> fetchFiles() async {
    try {

      final ListResult result = await FirebaseStorage.instance.ref().child('LabRecords/$_selectedValue').listAll();
      Map<String, String> fileUrls = {};
      for (final ref in result.items) {
        String url = await ref.getDownloadURL();
        fileUrls[ref.name] = url;
      }
      print('File List: $fileUrls');
      return fileUrls;
    } catch (e) {
      throw e.toString();
    }
  }

  void dispose() {
    utils.clearCache(); // Clear cache when the app is disposed
    super.dispose();
  }
}
