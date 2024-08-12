// import 'package:dio/dio.dart';
// import 'package:findany_flutter/services/pdfscreen.dart';
// import 'package:findany_flutter/utils/LoadingDialog.dart';
// import 'package:findany_flutter/utils/utils.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:http/http.dart' as http;
//
//
// class ShowFiles extends StatefulWidget {
//   const ShowFiles({super.key});
//
//   @override
//   State<ShowFiles> createState() => _ShowFilesState();
// }
//
// class _ShowFilesState extends State<ShowFiles> {
//   Utils utils = Utils();
//   LoadingDialog loadingDialog = LoadingDialog();
//   String _selectedValue = 'YEAR 1';
//   final Map<String, String> _selectedFiles = {};
//   Map<String, String> retrievedFiles = {};
//   Icon addIcon = const Icon(Icons.add);
//   Icon minusIcon = const Icon(Icons.remove);
//   TextEditingController searchController = TextEditingController();
//   bool isSearching = false;
//
//   @override
//   void initState() {
//     super.initState();
//     addIcon = const Icon(Icons.add);
//     minusIcon = const Icon(Icons.remove);
//     fetchFiles();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: !isSearching
//             ? const Text('Select')
//             : TextField(
//           controller: searchController,
//           autofocus: true,
//           decoration: const InputDecoration(
//             hintText: 'Search files...',
//             border: InputBorder.none,
//           ),
//           onChanged: (value) {
//             setState(() {});
//           },
//         ),
//         actions: [
//           if (!isSearching)
//             Padding(
//               padding: const EdgeInsets.only(right: 20.0),
//               child: Row(
//                 children: [
//                   DropdownButton(
//                     value: _selectedValue,
//                     onChanged: (newValue) {
//                       setState(() {
//                         _selectedValue = newValue.toString();
//                         fetchFiles();
//                       });
//                     },
//                     items: ['YEAR 1', 'YEAR 2', 'YEAR 3', 'YEAR 4', 'OTHER']
//                         .map<DropdownMenuItem<String>>((value) {
//                       return DropdownMenuItem<String>(
//                         value: value,
//                         child: Text(value),
//                       );
//                     }).toList(),
//                   ),
//                 ],
//               ),
//             ),
//           IconButton(
//             icon: isSearching ? const Icon(Icons.clear) : const Icon(Icons.search),
//             onPressed: () {
//               setState(() {
//                 if (isSearching) {
//                   searchController.clear();
//                 }
//                 isSearching = !isSearching;
//               });
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.check),
//             onPressed: () async{
//               loadingDialog.showDefaultLoading('Adding to your files');
//               // Get the application cache directory
//               final cacheDir = await getTemporaryDirectory();
//               final uploadDir = Directory('${cacheDir.path}/xeroxPdfs');
//
//               for (var entry in _selectedFiles.entries) {
//                 final key = entry.key; // Identifier or unique name for the file
//                 final firebaseUrl = entry.value; // Firebase URL of the file
//
//                 await downloadAndStoreFile(firebaseUrl, key, uploadDir);
//               }
//
//               print("Selected Files: $_selectedFiles");
//
//               Navigator.pop(context, _selectedFiles);
//               loadingDialog.dismiss();
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10.0),
//         child: retrievedFiles.isEmpty
//             ? const Center(
//           child: Text(
//             'No files found',
//             style: TextStyle(fontSize: 16.0),
//           ),
//         )
//             : ListView.builder(
//           itemCount: retrievedFiles.keys
//               .where((filename) => filename
//               .toLowerCase()
//               .contains(searchController.text.toLowerCase()))
//               .length,
//           itemBuilder: (context, index) {
//             String filename = retrievedFiles.keys
//                 .where((filename) => filename
//                 .toLowerCase()
//                 .contains(searchController.text.toLowerCase()))
//                 .elementAt(index);
//             String url = retrievedFiles[filename]!;
//             bool isSelected = _selectedFiles.containsKey(filename);
//
//             return Container(
//               margin: const EdgeInsets.symmetric(vertical: 5.0),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: ListTile(
//                       title: Text(filename),
//                       onTap: () {
//                         _downloadAndOpenFile(url, filename);
//                       },
//                     ),
//                   ),
//                   IconButton(
//                     icon: isSelected ? minusIcon : addIcon,
//                     onPressed: () {
//                       setState(() {
//                         if (isSelected) {
//                           _selectedFiles.remove(filename);
//                           utils.showToastMessage(
//                               '$filename removed from your xerox list',);
//                           print('Selected Files: $_selectedFiles');
//                         } else {
//                           _selectedFiles[filename] = url;
//                           utils.showToastMessage(
//                               '$filename added in your xerox list',);
//                           print('Selected Files: $_selectedFiles');
//                         }
//                       });
//                     },
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Future<void> fetchFiles() async {
//     loadingDialog.showDefaultLoading('Getting Files...');
//     try {
//       print('Fetching Files..');
//       final ListResult result = await FirebaseStorage.instance.ref().child('ShowFiles/$_selectedValue').listAll();
//       retrievedFiles.clear(); // Clear existing files
//       for (final ref in result.items) {
//         String url = await ref.getDownloadURL();
//         retrievedFiles[ref.name] = url;
//       }
//       print('File List: $retrievedFiles');
//       EasyLoading.dismiss();
//       setState(() {}); // Update UI after fetching files
//     } catch (e) {
//       EasyLoading.dismiss();
//       throw e.toString();
//     }
//   }
//
//   Future<void> downloadAndStoreFile(String firebaseUrl, String fileName,Directory uploadDir) async {
//     try {
//
//       // Create the directory if it does not exist
//       if (!await uploadDir.exists()) {
//         await uploadDir.create(recursive: true);
//       }
//
//       // Create the file path
//       final filePath = '${uploadDir.path}/$fileName';
//
//       // Send HTTP GET request to the Firebase URL
//       final response = await http.get(Uri.parse(firebaseUrl));
//
//       // Check if the request was successful
//       if (response.statusCode == 200) {
//         // Write the file to the directory
//         final file = File(filePath);
//         await file.writeAsBytes(response.bodyBytes);
//         print('File downloaded and saved to $filePath');
//         _selectedFiles[fileName] = filePath;
//       } else {
//         print('Failed to download file: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error downloading file: $e');
//     }
//   }
//
//   Future<void> _downloadAndOpenFile(String url, String filename) async {
//     try {
//       final dir = await getTemporaryDirectory(); // Get temporary directory
//       final filePath = '${dir.path}/FileSelection/$filename'; // Create file path
//
//       final file = File(filePath);
//
//       if (await file.exists()) {
//         // File already exists, open it directly
//         print('File already exists at $filePath');
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => PDFScreen(filePath: filePath, title: filename),
//           ),
//         );
//       } else {
//         // File does not exist, download it
//         loadingDialog.showDefaultLoading('Downloading...');
//         final dio = Dio();
//
//         await dio.download(url, filePath, onReceiveProgress: (received, total) {
//           if (total != -1) {
//             EasyLoading.showProgress(received / total, status: 'Downloading...');
//           }
//         });
//
//         EasyLoading.dismiss();
//         print('File downloaded to $filePath');
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => PDFScreen(filePath: filePath, title: filename),
//           ),
//         );
//       }
//     } catch (e) {
//       EasyLoading.dismiss();
//       print('Error downloading or opening file: $e');
//     }
//   }
//
//   @override
//   void dispose() {
//     utils.clearCache();
//     loadingDialog.dismiss();
//     searchController.dispose();
//     super.dispose();
//   }
// }


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../provider/showfiles_provider.dart';


class ShowFiles extends StatelessWidget {
  const ShowFiles({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShowFilesProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: !provider.searching
                ? const Text('Select')
                : TextField(
              controller: provider.searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search files...',
                border: InputBorder.none,
              ),
              onChanged: (value) {},
            ),
            actions: [
              if (!provider.searching)
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: Row(
                    children: [
                      DropdownButton(
                        value: provider.selectedValue,
                        onChanged: (newValue) {
                          provider.setSelectedValue(newValue.toString());
                        },
                        items: ['YEAR 1', 'YEAR 2', 'YEAR 3', 'YEAR 4', 'OTHER']
                            .map<DropdownMenuItem<String>>((value) {
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
                icon: provider.searching ? const Icon(Icons.clear) : const Icon(Icons.search),
                onPressed: () {
                  provider.toggleSearching();
                  if (provider.searching) {
                    provider.searchController.clear();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () async {
                  provider.loadingDialog.showDefaultLoading('Adding to your files');
                  final cacheDir = await getTemporaryDirectory();
                  final uploadDir = Directory('${cacheDir.path}/xeroxPdfs');

                  for (var entry in provider.selectedFiles.entries) {
                    final key = entry.key;
                    final firebaseUrl = entry.value;

                    await provider.downloadAndStoreFile(firebaseUrl, key);
                  }

                  Navigator.pop(context, provider.selectedFiles);
                  provider.loadingDialog.dismiss();
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: provider.files.isEmpty
                ? const Center(
              child: Text(
                'No files found',
                style: TextStyle(fontSize: 16.0),
              ),
            )
                : ListView.builder(
              itemCount: provider.files.keys
                  .where((filename) => filename.toLowerCase().contains(provider.searchController.text.toLowerCase()))
                  .length,
              itemBuilder: (context, index) {
                String filename = provider.files.keys
                    .where((filename) => filename.toLowerCase().contains(provider.searchController.text.toLowerCase()))
                    .elementAt(index);
                String url = provider.files[filename]!;
                bool isSelected = provider.selectedFiles.containsKey(filename);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text(filename),
                          onTap: () {
                            provider.downloadAndOpenFile(url, filename, context);
                          },
                        ),
                      ),
                      IconButton(
                        icon: isSelected ? provider.minusIcon : provider.addIcon,
                        onPressed: () {
                          if (isSelected) {
                            provider.removeFile(filename);
                          } else {
                            provider.addFile(filename, url);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
