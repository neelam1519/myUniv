import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfScreenProvider with ChangeNotifier {
  PdfViewerController? _pdfViewerController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  int _totalPages = 0;
  int _currentPage = 0;
  PdfTextSearchResult? _searchResult;

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
    if (_isSearching != value) {
      _isSearching = value;
      notifyListeners();
    }
  }

  set totalPages(int value) {
    if (_totalPages != value) {
      _totalPages = value;
      notifyListeners();
    }
  }

  set currentPage(int value) {
    if (_currentPage != value) {
      _currentPage = value;
      notifyListeners();
    }
  }

  void onSearchPressed() {
    isSearching = !isSearching;
  }

  void performSearch(String text) async {
    if (_pdfViewerController != null && text.isNotEmpty) {
      _searchResult = await _pdfViewerController!.searchText(text);
      if (_searchResult != null) {
        _searchResult!.addListener(notifyListeners);
      }
    }
  }

  void navigateSearchResult({bool backward = false}) {
    if (_searchResult != null) {
      if (backward) {
        _searchResult!.previousInstance();
      } else {
        _searchResult!.nextInstance();
      }
    }
  }

  void clearSearch() {
    if (_searchResult != null) {
      _searchResult!.clear();
    }
  }

  void onDocumentLoaded(PdfDocumentLoadedDetails details) {
    totalPages = details.document.pages.count;
    currentPage = _pdfViewerController?.pageNumber ?? 1;
  }

  void onPageChanged(PdfPageChangedDetails details) {
    currentPage = details.newPageNumber;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchResult?.removeListener(notifyListeners);
    super.dispose();
  }
}
