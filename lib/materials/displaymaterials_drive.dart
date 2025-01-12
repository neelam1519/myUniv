import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // Add shimmer package for shimmer effect
import '../services/cachemanager.dart';
import 'displaymaterials_drive_provider.dart';
import '../services/pdfscreen.dart';

class DriveMaterials extends StatefulWidget {
  final String year;
  final String branch;
  final String stream;
  final String unit;
  final String subject;

  const DriveMaterials({
    Key? key,
    required this.year,
    required this.branch,
    required this.stream,
    required this.unit,
    required this.subject,
  }) : super(key: key);

  @override
  _DriveMaterialsState createState() => _DriveMaterialsState();
}

class _DriveMaterialsState extends State<DriveMaterials> {
  int _currentIndex = 0;
  String currentView = 'PDFs'; // Default view

  @override
  void initState() {
    super.initState();
    _fetchMaterials('PDFs'); // Default fetch for PDFs
  }

  void _fetchMaterials(String type) {
    String path;

    if (type == 'PDFs') {
      path = "materials/${widget.year}/${widget.branch}/SUBJECTS/${widget.subject}/${widget.unit}/";
    } else {
      path = "materials/${widget.year}/${widget.branch}/SUBJECTS/${widget.subject}/QUESTIONPAPERS/";
    }

    print('Fetching materials from path: $path');
    DocumentReference documentReference = FirebaseFirestore.instance.doc(path);

    // Fetch the material list from Firestore
     context.read<PDFProvider>().getPdfList(documentReference);
  }

  Future<Widget> _generateThumbnail(String localPath) async {
    final document = await PdfDocument.openFile(localPath);
    final page = await document.getPage(1); // Load the first page
    final pageImage = await page.render(
      width: page.width,
      height: page.height,
      format: PdfPageImageFormat.jpeg,
    );
    await page.close();
    return Image.memory(pageImage!.bytes, fit: BoxFit.cover); // Render as thumbnail
  }

  void _openPdf(String localPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(pdfPath: localPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentView),
      ),
      body: Consumer<PDFProvider>(
        builder: (context, provider, child) {
          if (provider.totalpdfCount == null || provider.materials.isEmpty) {
            // Show CircularProgressIndicator until totalpdfCount is fetched
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.materials.isEmpty) {
            // Show shimmer effect based on totalpdfCount when data is loading
            int? shimmerCount = provider.totalpdfCount != null ? provider.totalpdfCount : 3; // Default to 3 if count is 0
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two shimmer cards per row
                childAspectRatio: 0.8, // Adjust the height-to-width ratio of cards
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              padding: const EdgeInsets.all(8),
              itemCount: shimmerCount, // Display shimmer based on totalpdfCount
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 120,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            );
          }

          final materials = provider.materials;
          String noMaterialsText = _currentIndex == 0 ? 'No PDFs Found' : 'No Question Papers Found';
          print('Materialss: $materials');
          if (materials.isEmpty) {
            return Center(
              child: Text(
                noMaterialsText,
                style: const TextStyle(fontSize: 18),
              ),
            );
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Show two cards per row
              childAspectRatio: 0.8, // Adjust the height-to-width ratio of cards
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            padding: const EdgeInsets.all(8),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final pdf = materials[index];
              if (pdf != null && pdf.localPath != null) {
                return FutureBuilder<Widget>(
                  future: _generateThumbnail(pdf.localPath!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 50, color: Colors.red),
                            const SizedBox(height: 8),
                            Text(
                              pdf.filename,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _openPdf(pdf.localPath!),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: snapshot.data,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                pdf.filename,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            currentView = index == 0 ? 'PDFs' : 'Question Papers';

            // Clear materials before fetching new ones
            context.read<PDFProvider>().clearMaterials();
            //print('Materials navigation: ${}');

            _fetchMaterials(currentView);
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'PDFs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Question Papers',
          ),
        ],
      ),

    );
  }
}
