// lib/screens/pdf_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../provider/pdfscreen_provider.dart';

class PDFScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const PDFScreen({super.key, required this.filePath, required this.title});

  @override
  State<PDFScreen> createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> {
  PdfScreenProvider? pdfScreenProvider;

  @override
  void initState() {
    super.initState();
    pdfScreenProvider = Provider.of<PdfScreenProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pdfScreenProvider?.pdfViewerController = PdfViewerController();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfScreenProvider>(
      builder: (context, pdfProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: pdfProvider.isSearching
                ? TextField(
              controller: pdfProvider.searchController,
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
              ),
              onSubmitted: (text) {
                pdfProvider.performSearch(text);
              },
            )
                : Text(widget.title),
            actions: pdfProvider.isSearching
                ? [
              IconButton(
                key: const Key('clear_search_button'),
                icon: const Icon(Icons.clear),
                onPressed: () {
                  pdfProvider.searchController.clear();
                  pdfProvider.isSearching = false;
                  pdfProvider.clearSearch();
                },
              ),
            ]
                : [
              IconButton(
                key: const Key('search_button'),
                icon: const Icon(Icons.search),
                onPressed: pdfProvider.onSearchPressed,
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: SfPdfViewer.file(
                  File(widget.filePath),
                  controller: pdfProvider.pdfViewerController,
                  onDocumentLoaded: pdfProvider.onDocumentLoaded,
                  onPageChanged: pdfProvider.onPageChanged,
                  enableDoubleTapZooming: false,
                  canShowScrollStatus: false,
                  canShowPaginationDialog: false,
                ),
              ),
              if (pdfProvider.isSearching)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: () {
                          pdfProvider.navigateSearchResult(backward: true);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: () {
                          pdfProvider.navigateSearchResult();
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
