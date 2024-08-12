// import 'package:findany_flutter/universitynews/addnews.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:io';
//
// class NewsDetailScreen extends StatefulWidget {
//   final String title;
//   final String summary;
//   final String details;
//   final String? pdfUrl;
//   final bool isAdmin;
//   final String documentID;
//
//   const NewsDetailScreen({super.key,
//     required this.title,
//     required this.details,
//     this.pdfUrl,
//     required this.isAdmin,
//     required this.summary,
//     required this.documentID
//   });
//
//   @override
//   State<NewsDetailScreen> createState() => _NewsDetailScreenState();
// }
//
// class _NewsDetailScreenState extends State<NewsDetailScreen> {
//   String? localPdfPath;
//   bool _isLoading = true;
//   String? _error;
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.pdfUrl != null) {
//       _downloadPdf();
//     } else {
//       _isLoading = false;
//     }
//     print('Document Name: ${widget.documentID}');
//   }
//
//   Future<void> _downloadPdf() async {
//     try {
//       final url = widget.pdfUrl!;
//       final filename = url.substring(url.lastIndexOf("/") + 1);
//       final dir = await getApplicationDocumentsDirectory();
//       final file = File('${dir.path}/$filename');
//
//       if (await file.exists()) {
//         setState(() {
//           localPdfPath = file.path;
//           _isLoading = false;
//         });
//       } else {
//         final response = await http.get(Uri.parse(url));
//         if (response.statusCode == 200) {
//           await file.writeAsBytes(response.bodyBytes);
//           setState(() {
//             localPdfPath = file.path;
//             _isLoading = false;
//           });
//         } else {
//           setState(() {
//             _error = 'Failed to load PDF: ${response.reasonPhrase}';
//             _isLoading = false;
//           });
//         }
//       }
//     } catch (e) {
//       setState(() {
//         _error = 'Error downloading PDF: $e';
//         _isLoading = false;
//       });
//       print('Error downloading PDF: $e');
//     }
//   }
//
//   void viewPdfFullScreen(String? filepath) {
//     if (filepath != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => Scaffold(
//             appBar: AppBar(
//               title: Text(widget.title),
//             ),
//             body: PDFView(
//               filePath: filepath,
//             ),
//           ),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//         actions: widget.isAdmin
//             ? [
//           IconButton(
//             icon: const Icon(Icons.edit),
//             onPressed:(){
//               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AddNews(title: widget.title, summary: widget.summary, details: widget.details,pdfUrl: widget.pdfUrl, documentID: widget.documentID,)));
//             },
//           ),
//         ]
//             : null,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 widget.details,
//                 style: const TextStyle(fontSize: 16.0, height: 1.5),
//               ),
//               const SizedBox(height: 16.0),
//               if (_isLoading)
//                 const Center(child: CircularProgressIndicator())
//               else if (_error != null)
//                 Text(_error!, style: const TextStyle(color: Colors.red))
//               else if (localPdfPath != null)
//                   Column(
//                     children: [
//                       SizedBox(
//                         height: 500,
//                         child: PDFView(
//                           filePath: localPdfPath,
//                         ),
//                       ),
//                       const SizedBox(height: 16.0),
//                       ElevatedButton.icon(
//                         onPressed: (){
//                           viewPdfFullScreen(localPdfPath);
//                         },
//                         icon: const Icon(Icons.fullscreen),
//                         label: const Text('View PDF Full Screen'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green[700],
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
//                           textStyle: const TextStyle(fontSize: 16.0),
//                         ),
//                       ),
//                     ],
//                   )
//                 else
//                   const Text(''),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
// }


import 'package:findany_flutter/provider/newsdetailsscreen_provider.dart';
import 'package:findany_flutter/universitynews/addnews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';

class NewsDetailScreen extends StatefulWidget {
  final String title;
  final String summary;
  final String details;
  final String? pdfUrl;
  final bool isAdmin;
  final String documentID;

  const NewsDetailScreen({
    super.key,
    required this.title,
    required this.details,
    this.pdfUrl,
    required this.isAdmin,
    required this.summary,
    required this.documentID,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.pdfUrl != null) {
      Future.microtask(() {
        Provider.of<NewsDetailsScreenProvider>(context, listen: false)
            .downloadPdf(widget.pdfUrl!);
      });
    }
  }

  void viewPdfFullScreen(String? filepath) {
    if (filepath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: PDFView(
              filePath: filepath,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.isAdmin
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AddNews(
                    title: widget.title,
                    summary: widget.summary,
                    details: widget.details,
                    pdfUrl: widget.pdfUrl,
                    documentID: widget.documentID,
                  ),
                ),
              );
            },
          ),
        ]
            : null,
      ),
      body: Consumer<NewsDetailsScreenProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.details,
                    style: const TextStyle(fontSize: 16.0, height: 1.5),
                  ),
                  const SizedBox(height: 16.0),
                  if (provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (provider.error != null)
                    Text(provider.error!, style: const TextStyle(color: Colors.red))
                  else if (provider.localPdfPath != null)
                      Column(
                        children: [
                          SizedBox(
                            height: 500,
                            child: PDFView(
                              filePath: provider.localPdfPath!,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton.icon(
                            onPressed: () {
                              viewPdfFullScreen(provider.localPdfPath);
                            },
                            icon: const Icon(Icons.fullscreen),
                            label: const Text('View PDF Full Screen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                              textStyle: const TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(''),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
