import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file_plus/open_file_plus.dart';
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
  int? fileCount;

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    setState(() => _isLoading = true);

    try {
      await _driveService.authenticate();

      fileCount =await _driveService.countFilesInFolder(widget.unitID);
      print("File Count: $fileCount");

      Stream<File> filesStream = _driveService.listFilesInFolderWithCache(widget.unitID);

      await for (var file in filesStream) {
        print('File: ${file.uri}');
        setState(() {
          _materials.add({
            'filename': file.uri.pathSegments.last,
            'localPath': file.path,
          });
        });
        _isLoading = false;
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
    OpenFile.open(localPath);
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => PdfViewerScreen(pdfPath: localPath),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unitName),
      ),
      body: fileCount == null
          ? pdfShimmer() // Show shimmer while fileCount is null
          : fileCount == 0
          ? const Center(
        child: Text(
          'No Materials Found for this subject',
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
        itemCount: fileCount, // Use fileCount for the number of cards
        itemBuilder: (context, index) {
          if (index < _materials.length) {
            final pdf = _materials[index];

            if (pdf['localPath'] != null) {
              return FutureBuilder<Widget>(
                future: _generateThumbnail(pdf['localPath']!),
                builder: (context, snapshot) {
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
                              child: snapshot.connectionState ==
                                  ConnectionState.waiting
                                  ? const Center(
                                child:
                                CircularProgressIndicator(),
                              ) // Show loading dialog
                                  : snapshot.hasError
                                  ? Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.error,
                                      size: 50,
                                      color: Colors.red),
                                  SizedBox(height: 8),
                                  Text(
                                    'Error Loading Thumbnail',
                                    textAlign:
                                    TextAlign.center,
                                  ),
                                ],
                              )
                                  : snapshot.data,
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
            }
          }
          // Placeholder for files not yet loaded
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(), // Show loading indicator
            ),
          );
        },
      ),
    );
  }


  Widget pdfShimmer(){
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      padding: const EdgeInsets.all(8),
      itemCount: 6,
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
}
