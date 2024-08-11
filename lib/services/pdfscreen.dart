import 'dart:io';
import 'package:findany_flutter/provider/pdfscreen_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_){
      pdfScreenProvider?.pdfViewerController = PdfViewerController();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<PdfScreenProvider>(
      builder: (context, pdfProvider, child){
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: pdfProvider.onSearchPressed,
              ),
            ],
          ),
          body: Column(
            children: [
              if (pdfProvider.isSearching)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: pdfProvider.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => pdfProvider.performSearch(pdfProvider.searchController.text),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: SfPdfViewer.file(
                  File(widget.filePath),
                  controller: pdfProvider.pdfViewerController,
                  onDocumentLoaded: pdfProvider.onDocumentLoaded,
                  onPageChanged: pdfProvider.onPageChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Page ${pdfProvider.currentPage} of ${pdfProvider.totalPages}'),
              ),
            ],
          ),
        );
      },
    );
  }
}
