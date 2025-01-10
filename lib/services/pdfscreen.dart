import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath; // Path to the PDF file

  const PdfViewerScreen({Key? key, required this.pdfPath}) : super(key: key);

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfControllerPinch _pdfPinchController;

  @override
  void initState() {
    super.initState();
    _pdfPinchController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.pdfPath),
    );
  }

  @override
  void dispose() {
    _pdfPinchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Viewer')),
      body: PdfViewPinch(
        controller: _pdfPinchController,
        onDocumentLoaded: (document) {
          print('PDF Loaded: ${document.pagesCount} pages.');
        },
        onPageChanged: (page) {
          print('Page changed to: $page');
        },
      ),
    );
  }
}
