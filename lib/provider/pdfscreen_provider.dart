import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfScreenProvider with ChangeNotifier {
  PdfViewerController? _pdfViewerController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  int _totalPages = 0;
  int _currentPage = 0;

  PdfViewerController? get pdfViewerController => _pdfViewerController;
  TextEditingController get searchController => _searchController;
  bool get isSearching => _isSearching;
  int get totalPages => _totalPages;
  int get currentPage => _currentPage;

  set pdfViewerController(PdfViewerController? controller) {
    _pdfViewerController = controller;
    notifyListeners();
  }

  set isSearching(bool value) {
    _isSearching = value;
    notifyListeners();
  }

  set totalPages(int value) {
    _totalPages = value;
    notifyListeners();
  }

  set currentPage(int value) {
    _currentPage = value;
    notifyListeners();
  }

  void onSearchPressed() {
    isSearching = !isSearching;
  }

  void performSearch(String text) {
    if (_pdfViewerController != null) {
      _pdfViewerController!.searchText(text);
    }
  }

  void onDocumentLoaded(PdfDocumentLoadedDetails details) {
    totalPages = details.document.pages.count;
    currentPage = _pdfViewerController?.pageNumber ?? 0;
  }

  void onPageChanged(PdfPageChangedDetails details) {
    currentPage = details.newPageNumber;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
