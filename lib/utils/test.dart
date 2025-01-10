import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PDFViewerPage extends StatefulWidget {
  final String pdfUrl;

  const PDFViewerPage({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePDF(widget.pdfUrl);
  }

  // Download the PDF and save it locally
  Future<void> _downloadAndSavePDF(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/temp.pdf');
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        localPath = file.path;
      });
    } catch (e) {
      print('Error downloading PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Viewer')),
      body: localPath != null
          ? PDFView(
        filePath: localPath!,
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
