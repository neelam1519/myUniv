import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart'; // To work with file paths

class CustomCacheManager {

  Future<File> downloadAndCachePDF(String url, String originalName,String folderID) async {
    print('Url: $url');
    final cacheManager = CacheManager(
      Config(
        'pdf_cache/$folderID', // Use a static cache key for simplicity
        stalePeriod: const Duration(days: 3), // Cache expiration period (3 days)
        maxNrOfCacheObjects: 100, // Max number of cache objects
      ),
    );

    try {
      final file = await cacheManager.getSingleFile(url);

      // Ensure correct file extension and naming
      return _ensureCorrectFilename(file, originalName);
    } catch (e) {
      print('Error downloading or fetching PDF: $e');
      rethrow;
    }
  }

  File _ensureCorrectFilename(File file, String originalName) {
    final directory = file.parent;
    final correctName = _sanitizeFilename(originalName);

    final correctPath = '${directory.path}/$correctName';

    // Rename the file if it doesn't match the original name
    if (file.path != correctPath) {
      final renamedFile = file.renameSync(correctPath);
      print('File renamed to: ${renamedFile.path}');
      return renamedFile;
    }
    return file;
  }

  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[\/:*?"<>|]'), '_');
  }

  static Future<File> _ensurePdfExtension(File file) async {
    if (file.path.endsWith('.pdf')) {
      return file;
    }

    final directory = await Directory.systemTemp.createTemp();
    final newFilePath = '${directory.path}/${basenameWithoutExtension(file.path)}.pdf';
    final newFile = await file.copy(newFilePath);

    print('Renamed file to ensure .pdf extension: $newFilePath');
    return newFile;
  }

  /// Clears the cache for the given cache key.
  static Future<void> clearCache(String cacheKey) async {
    final cacheManager = CacheManager(
      Config(
        cacheKey, // Custom cache key
        stalePeriod: const Duration(days: 7), // Cache expiration period (7 days)
        maxNrOfCacheObjects: 100, // Max number of cache objects
      ),
    );
    await cacheManager.emptyCache();
    print('Cache cleared for key: $cacheKey');
  }
}
