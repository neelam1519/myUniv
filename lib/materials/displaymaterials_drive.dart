import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shimmer/shimmer.dart';
import '../apis/googleDrive.dart';
import '../services/pdfscreen.dart';

class DriveMaterials extends StatefulWidget {
  final String unitID;
  final String unitName;

  const DriveMaterials({Key? key, required this.unitID, required this.unitName}) : super(key: key);

  @override
  _DriveMaterialsState createState() => _DriveMaterialsState();
}

class _DriveMaterialsState extends State<DriveMaterials> {
  final GoogleDriveService _driveService = GoogleDriveService();
  List<Map<String, String?>> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    setState(() => _isLoading = true);

    try {
      await _driveService.authenticate();

      Stream<File> filesStream = _driveService.listFilesInFolderWithCache(widget.unitID);

      await for (var file in filesStream) {
        setState(() {
          _materials.add({
            'filename': file.uri.pathSegments.last,
            'localPath': file.path,
          });
        });
      }
    } catch (e) {
      print('Error fetching materials: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Widget> _generateThumbnail(String localPath) async {
    final document = await PdfDocument.openFile(localPath);
    final page = await document.getPage(1);
    final pageImage = await page.render(
      width: page.width,
      height: page.height,
      format: PdfPageImageFormat.jpeg,
    );
    await page.close();
    return Image.memory(pageImage!.bytes, fit: BoxFit.cover);
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
        title: Text(widget.unitName),
      ),
      body: _isLoading
          ? GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        padding: const EdgeInsets.all(8),
        itemCount: 6, // Show shimmer placeholders
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
      )
          : _materials.isEmpty
          ? const Center(
        child: Text(
          'No PDFs Found',
          style: TextStyle(fontSize: 18),
        ),
      )
          : GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        padding: const EdgeInsets.all(8),
        itemCount: _materials.length,
        itemBuilder: (context, index) {
          final pdf = _materials[index];

          if (pdf['localPath'] != null) {
            return FutureBuilder<Widget>(
              future: _generateThumbnail(pdf['localPath']!),
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
                          pdf['filename'] ?? 'Unknown File',
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
                    onTap: () => _openPdf(pdf['localPath']!),
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
                            pdf['filename'] ?? 'Unknown File',
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
      ),
    );
  }
}
