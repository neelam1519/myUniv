
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

  @override
  _ShowFilesState createState() => _ShowFilesState();
}

class _ShowFilesState extends State<ShowFiles> {
  Utils utils = Utils();
  LoadingDialog loadingDialog = LoadingDialog();
  String _selectedValue = '1'; // Default selected value
  Map<String, String> _selectedFiles = {}; // List to store selected file names

  Map<String,String> retrievedFiles = {};
  Icon addIcon = Icon(Icons.add);
  Icon minusIcon = Icon(Icons.remove);

  @override
  void initState() {
    super.initState();
    addIcon = Icon(Icons.add); // Initialize add icon
    minusIcon = Icon(Icons.remove); // Initialize remove icon
    fetchFiles(); // Fetch files when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xerox Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Row(
              children: [
                Text(
                  'Year',
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton(
                  value: _selectedValue,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedValue = newValue.toString();
                      fetchFiles();
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
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedFiles);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: retrievedFiles.isEmpty ? Center(
          child: Text(
            'No files found',
            style: TextStyle(fontSize: 16.0),
          ),
        ) :
        ListView.builder(
          itemCount: retrievedFiles.length,
          itemBuilder: (context, index) {
            String filename = retrievedFiles.keys.elementAt(index);
            String url = retrievedFiles.values.elementAt(index);
            bool isSelected = _selectedFiles.containsKey(filename);

            return Container(
              margin: EdgeInsets.symmetric(vertical: 5.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(filename),
                      onTap: () {
                        _downloadAndOpenFile(url, filename);
                      },
                    ),
                  ),
                  IconButton(
                    icon: isSelected ? minusIcon : addIcon,
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          _selectedFiles.remove(filename);
                          utils.showToastMessage('$filename removed from your xerox list', context);
                        } else {
                          _selectedFiles[filename] = url;
                          utils.showToastMessage('$filename added in your xerox list', context);
                        }

                      });

                      print("Selected Files: ${_selectedFiles.toString()}");
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  Future<void> fetchFiles() async {
    loadingDialog.showDefaultLoading('Getting Files...');
    try {
      print('Fetching Files..');
      final ListResult result = await FirebaseStorage.instance.ref().child('ShowFiles/$_selectedValue').listAll();
      retrievedFiles.clear(); // Clear existing files
      for (final ref in result.items) {
        String url = await ref.getDownloadURL();
        retrievedFiles[ref.name] = url;
      }
      print('File List: $retrievedFiles');
      EasyLoading.dismiss();
      setState(() {}); // Update UI after fetching files
    } catch (e) {
      EasyLoading.dismiss();
      throw e.toString();

    }
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

      EasyLoading.dismiss();
      setState(() {});
      await OpenFile.open(filePath);
    } catch (e) {
      EasyLoading.dismiss(); // Dismiss progress indicator in case of error
      print('Error downloading or opening file: $e');
    }
  }

  void dispose() {
    utils.clearCache(); // Clear cache when the app is disposed
    super.dispose();
  }
}
