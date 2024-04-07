import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class XeroxDetailView extends StatefulWidget {
  final Map<String, dynamic> data;

  XeroxDetailView({required this.data});

  @override
  _XeroxDetailViewState createState() => _XeroxDetailViewState();
}

class _XeroxDetailViewState extends State<XeroxDetailView> {
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
              padding: const EdgeInsets.only(left: 16.0), // Add padding to the left side
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
                      children: uploadFiles
                          .map((url) => InkWell(
                        onTap: () => _launchUrl(url),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(url),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          }

          else {
            return ListTile(
              title: Text('$key:'),
              subtitle: Text(value.toString()),
            );
          }
        },
      ),
    );
  }

  Future<void> _launchUrl(String stringUrl) async {
    final Uri _url = Uri.parse(stringUrl);

    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }



}
