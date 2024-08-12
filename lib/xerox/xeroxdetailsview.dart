// import 'package:dio/dio.dart';
// import 'package:findany_flutter/utils/LoadingDialog.dart';
// import 'package:findany_flutter/utils/utils.dart';
// import 'package:flutter/material.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
//
// import '../services/pdfscreen.dart';
//
// class XeroxDetailView extends StatefulWidget {
//   final Map<String, dynamic> data;
//
//   const XeroxDetailView({super.key, required this.data});
//
//   @override
//   State<XeroxDetailView> createState() => _XeroxDetailViewState();
// }
//
// class _XeroxDetailViewState extends State<XeroxDetailView> {
//   LoadingDialog loadingDialog = LoadingDialog();
//   Utils utils = Utils();
//   List<String> order = ['ID', 'Name', 'Mobile Number', 'Email', 'Date', 'Transaction ID', 'Description', 'Uploaded Files'];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Xerox Details'),
//       ),
//       body: ListView.builder(
//         itemCount: order.length,
//         itemBuilder: (context, index) {
//           String key = order[index];
//           dynamic value = widget.data[key];
//           print('Key: $key  Value :$value');
//           if (key == 'Uploaded Files') {
//             List<String> uploadFiles = List<String>.from(value.map((file) => file.toString()));
//             uploadFiles = uploadFiles.map((file) => file.trim()).toList(); // Trim each URL
//             return Padding(
//               padding: const EdgeInsets.only(left: 16.0, bottom: 18.0), // Add padding to the left side and bottom
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '$key:',
//                     style: const TextStyle(
//                       fontSize: 16, // Adjust font size as needed
//                     ),
//                   ),
//                   const SizedBox(height: 8), // Add some space between the title and the list items
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: uploadFiles.map((url) => InkWell(
//                         onTap: () {
//                           downloadAndOpenFile(url,'historyfile');
//                           print('Selected Url: $url');
//                         },
//                         child: Padding(
//                           padding: const EdgeInsets.only(bottom: 8.0), // Add padding to the bottom
//                           child: Text(getFileNameFromUrl(url)),
//                         ),
//                       ))
//                           .toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           } else {
//             return ListTile(
//               title: Text('$key:'),
//               subtitle: Text(value.toString()),
//             );
//           }
//         },
//       ),
//     );
//   }
//
//   String getFileNameFromUrl(String url) {
//     Uri uri = Uri.parse(Uri.decodeFull(url));
//     return uri.pathSegments.last;
//   }
//
//   Future<void> downloadAndOpenFile(String url, String filename) async {
//     try {
//       loadingDialog.showDefaultLoading('Downloading...'); // Show progress indicator
//       final dio = Dio();
//       final dir = await getTemporaryDirectory(); // Get temporary directory
//       final filePath = '${dir.path}/FileSelection/$filename'; // Create file path
//
//       print('Temp File Path: $filePath');
//
//       await dio.download(url, filePath, onReceiveProgress: (received, total) {
//         if (total != -1) {
//           loadingDialog.showProgressLoading(received / total, 'Downloading...');
//         }
//       });
//       loadingDialog.dismiss();
//       setState(() {});
//
//       String extension = path.extension(Uri.parse(url).path).toLowerCase();
//       print('Extension: $extension');
//       String mimeType = utils.getMimeType(extension);
//       print('Mime Type: $mimeType');
//       viewPdfFullScreen(filePath,filePath.split('/').last);
//     } catch (e) {
//       loadingDialog.dismiss(); // Dismiss progress indicator in case of error
//       print('Error downloading or opening file: $e');
//     }
//   }
//
//   void viewPdfFullScreen(String? filePath, String title) {
//     if (filePath != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => PDFScreen(filePath: filePath, title: title),
//         ),
//       );
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/xeroxdetailsview_provider.dart';

class XeroxDetailView extends StatelessWidget {
  final Map<String, dynamic> data;

  const XeroxDetailView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<XeroxDetailProvider>(context, listen: true);
    provider.setData(data);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xerox Details'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.order.length,
              itemBuilder: (context, index) {
                String key = provider.order[index];
                dynamic value = provider.data[key];
                if (key == 'Uploaded Files') {
                  List<String> uploadFiles = List<String>.from(value.map((file) => file.toString()));
                  uploadFiles = uploadFiles.map((file) => file.trim()).toList();
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$key:', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: uploadFiles
                                .map((url) => InkWell(
                                      onTap: () {
                                        provider.downloadAndOpenFile(url, provider.getFileNameFromUrl(url), context);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Text(provider.getFileNameFromUrl(url)),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListTile(
                    title: Text('$key:'),
                    subtitle: Text(value.toString()),
                  );
                }
              },
            ),
    );
  }
}
