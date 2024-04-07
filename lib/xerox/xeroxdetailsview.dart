import 'package:dio/dio.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class XeroxDetailView extends StatefulWidget {
  final Map<String, dynamic> data;

  XeroxDetailView({required this.data});

  @override
  _XeroxDetailViewState createState() => _XeroxDetailViewState();
}

class _XeroxDetailViewState extends State<XeroxDetailView> {
  LoadingDialog loadingDialog = new LoadingDialog();
  List<String> order = ['ID', 'Name', 'Mobile Number', 'Email', 'Date', 'No of Pages', 'Transaction ID', 'Description', 'Uploaded Files'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xerox Details'),
      ),
      body: ListView.builder(
        itemCount: order.length,
        itemBuilder: (context, index) {
          String key = order[index];
          dynamic value = widget.data[key];
          print('Key: $key  Value :$value');
          if (key == 'Uploaded Files') {
            List<String> uploadFiles = List<String>.from(value.map((file) => file.toString()));
            uploadFiles = uploadFiles.map((file) => file.trim()).toList(); // Trim each URL
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 18.0), // Add padding to the left side and bottom
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$key:',
                    style: TextStyle(
                      fontSize: 16, // Adjust font size as needed
                    ),
                  ),
                  SizedBox(height: 8), // Add some space between the title and the list items
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: uploadFiles.map((url) => InkWell(
                        onTap: () {
                          _downloadAndOpenFile(url,'historyfile');
                          print('Selected Url: $url');
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0), // Add padding to the bottom
                          child: Text(getFileNameFromUrl(url)),
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


  String getFileNameFromUrl(String url) {
    Uri uri = Uri.parse(Uri.decodeFull(url));
    return uri.pathSegments.last;
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

}
