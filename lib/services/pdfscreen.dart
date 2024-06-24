import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFScreen extends StatefulWidget {
  final String filePath;
  final String title;

  PDFScreen({required this.filePath, required this.title});

  @override
  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isPDFLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!_isPDFLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Page $_currentPage/$_totalPages',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: PDFView(
        filePath: widget.filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: false,
        onRender: (pages) {
          setState(() {
            _totalPages = pages ?? 0;
            _isPDFLoading = false;
          });
        },
        onViewCreated: (controller) {
          controller.setPage(_currentPage);
        },
        onPageChanged: (currentPage, totalPages) {
          setState(() {
            _currentPage = (currentPage ?? 0) + 1;
          });
        },
        onError: (error) {
          print(error.toString());
        },
      ),
    );
  }
}