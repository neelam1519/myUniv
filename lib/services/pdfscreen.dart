import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PDFScreen extends StatefulWidget {
  final String filePath;
  final String title;

  PDFScreen({required this.filePath, required this.title});

  @override
  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> {
  late PdfViewerController _pdfController;
  late PdfTextSearcher _textSearcher;
  String _searchTerm = '';
  bool _isSearching = false;
  bool _noMatchesFound = false;
  bool _toastShown = false;

  Utils utils = Utils();

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _textSearcher = PdfTextSearcher(_pdfController)
      ..addListener(_updateSearchResults);
  }

  void _updateSearchResults() {
    if (mounted) {
      final hasMatches = _textSearcher.matches.isNotEmpty;

      setState(() {
        _noMatchesFound = !hasMatches;
      });

      if (_noMatchesFound && !_toastShown) {
        if(_searchTerm.isNotEmpty) {
          utils.showToastMessage("No matches found for $_searchTerm", context);
          _toastShown = true;
        }
      }
    }
  }

  @override
  void dispose() {
    _textSearcher.removeListener(_updateSearchResults);
    _textSearcher.dispose();
    super.dispose();
  }

  void _startSearch(String term) {
    setState(() {
      _isSearching = true;
      _searchTerm = term;
      _noMatchesFound = false;
      _toastShown = false; // Reset the flag for new search
    });
    _textSearcher.startTextSearch(term, caseInsensitive: true);
  }

  void _cancelSearch() {
    setState(() {
      _isSearching = false;
      _searchTerm = '';
      _noMatchesFound = false;
      _toastShown = false; // Reset the flag when search is canceled
    });
    _textSearcher.resetTextSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter search term',
            border: InputBorder.none,
          ),
          onSubmitted: (term) {
            if (term.isNotEmpty) {
              _startSearch(term);
            }
          },
        )
            : Text(widget.title),
        actions: [
          _isSearching
              ? IconButton(
            icon: Icon(Icons.close),
            onPressed: _cancelSearch,
          )
              : IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        ],
      ),
      body: PdfViewer.file(
        widget.filePath,
        controller: _pdfController,
        params: PdfViewerParams(
          // Show loading indicator while loading PDF
          loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
            return Center(
              child: CircularProgressIndicator(
                value: totalBytes != null ? bytesDownloaded / totalBytes : null,
                backgroundColor: Colors.grey,
              ),
            );
          },
          // Display page number at the bottom of each page
          pageOverlaysBuilder: (context, pageRect, page) {
            return [
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'Page ${page.pageNumber}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ];
          },
          // Highlight search matches
          pagePaintCallbacks: [
            _textSearcher.pageTextMatchPaintCallback,
          ],
        ),
      ),
      floatingActionButton: _isSearching && _textSearcher.matches.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () {
          _textSearcher.goToNextMatch();
        },
        label: Text('Next Match'),
        icon: Icon(Icons.search),
      )
          : null,
    );
  }
}
