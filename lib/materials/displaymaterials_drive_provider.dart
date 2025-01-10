import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/cachemanager.dart';

class PDFProvider with ChangeNotifier {
  List<MaterialsPDFModel?>? _materials;

  List<MaterialsPDFModel?>? get materials => _materials;

  final FireStoreService fireStoreService = FireStoreService();

  Future<void> getPdfList(DocumentReference docRef) async {
    try {
      _materials = null;
      notifyListeners();

      Map<String, dynamic>? materials = await fireStoreService.getDocumentDetails(docRef);
      if (materials != null && materials.isNotEmpty) {
        _materials = [];

        for (var key in materials.keys) {
          String pdfUrl = materials[key];

          // Convert shareable link to direct download link
          pdfUrl = convertToDownloadUrl(pdfUrl);

          CustomCacheManager.downloadAndCachePDF(pdfUrl, docRef.path).then((cachedFile) {
            MaterialsPDFModel pdfModel = MaterialsPDFModel(
              filename: key,
              localPath: cachedFile.path, // Store the local path of the cached file
            );

            // Add the downloaded PDF to the list and notify listeners
            _materials!.add(pdfModel);
            notifyListeners();
          }).catchError((e) {
            print('Error downloading PDF $key: $e');
          });
        }
      } else {
        _materials = []; // Set to an empty list if no materials are found
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching PDFs: $e');
      _materials = []; // Handle errors by setting materials to an empty list
      notifyListeners();
    }
  }

  String convertToDownloadUrl(String shareableUrl) {
    final regex = RegExp(r'https:\/\/drive\.google\.com\/file\/d\/([^\/]+)\/view\?usp=sharing');
    final match = regex.firstMatch(shareableUrl);

    if (match != null && match.groupCount > 0) {
      String fileId = match.group(1)!;
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }

    // If the URL doesn't match, return the original URL
    return shareableUrl;
  }
}

class MaterialsPDFModel {
  final String filename;
  String? localPath;

  MaterialsPDFModel({required this.filename, required this.localPath});
}
