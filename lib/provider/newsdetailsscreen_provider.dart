import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class NewsDetailsScreenProvider with ChangeNotifier {
  String? _localPdfPath;
  bool _isLoading = true;
  String? _error;

  String? get localPdfPath => _localPdfPath;
  bool get isLoading => _isLoading;
  String? get error => _error;


  Future<void> downloadPdf(String pdfUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filename = pdfUrl.substring(pdfUrl.lastIndexOf("/") + 1);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');

      if (await file.exists()) {
        _localPdfPath = file.path;
      } else {
        final response = await http.get(Uri.parse(pdfUrl));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          _localPdfPath = file.path;
        } else {
          _error = 'Failed to load PDF: ${response.reasonPhrase}';
        }
      }
    } catch (e) {
      _error = 'Error downloading PDF: $e';
      print('Error downloading PDF: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
