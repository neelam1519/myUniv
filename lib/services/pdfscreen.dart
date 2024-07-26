import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFScreen extends StatefulWidget {
  final String filePath;
  final String title;

  PDFScreen({required this.filePath, required this.title});

  @override
  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> {
  late PdfViewerController _pdfViewerController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  void _onSearchPressed() {
    setState(() {
      _isSearching = !_isSearching;
    });
  }

  void _performSearch(String text) {
    _pdfViewerController.searchText(text);
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
      _currentPage = _pdfViewerController.pageNumber;
    });
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _onSearchPressed,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () => _performSearch(_searchController.text),
                  ),
                ),
              ),
            ),
          Expanded(
            child: SfPdfViewer.file(
              File(widget.filePath),
              controller: _pdfViewerController,
              onDocumentLoaded: _onDocumentLoaded,
              onPageChanged: _onPageChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Page $_currentPage of $_totalPages'),
          ),
        ],
      ),
    );
  }
}
