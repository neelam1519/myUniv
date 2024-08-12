import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import '../services/pdfscreen.dart';

class XeroxDetailProvider extends ChangeNotifier {
  final LoadingDialog _loadingDialog = LoadingDialog();
  final Utils _utils = Utils();
  late List<String> _order;
  Map<String, dynamic> _data = {};
  bool _isLoading = false;
  String? _filePath;

  bool get isLoading => _isLoading;

  String? get filePath => _filePath;

  XeroxDetailProvider() {
    _order = ['ID', 'Name', 'Mobile Number', 'Email', 'Date', 'Transaction ID', 'Description', 'Uploaded Files'];
  }

  void setData(Map<String, dynamic> data) {
    _data = data;
    notifyListeners();
  }

  Future<void> downloadAndOpenFile(String url, String filename, BuildContext context) async {
    try {
      _loadingDialog.showDefaultLoading('Downloading...');
      _isLoading = true;
      notifyListeners();

      final dio = Dio();
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/FileSelection/$filename';

      await dio.download(url, filePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          _loadingDialog.showProgressLoading(received / total, 'Downloading...');
        }
      });

      _filePath = filePath;
      _isLoading = false;
      _loadingDialog.dismiss();
      notifyListeners();

      String extension = path.extension(Uri.parse(url).path).toLowerCase();
      String mimeType = _utils.getMimeType(extension);
      viewPdfFullScreen(filePath, filename, context);
    } catch (e) {
      _isLoading = false;
      _loadingDialog.dismiss();
      notifyListeners();
      print('Error downloading or opening file: $e');
    }
  }

  void viewPdfFullScreen(String filePath, String title, BuildContext context) {
    if (filePath.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFScreen(filePath: filePath, title: title),
        ),
      );
    }
  }

  String getFileNameFromUrl(String url) {
    Uri uri = Uri.parse(Uri.decodeFull(url));
    return uri.pathSegments.last;
  }

  List<String> get order => _order;

  Map<String, dynamic> get data => _data;
}
