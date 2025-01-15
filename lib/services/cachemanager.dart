import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart'; // To work with file paths

class CustomCacheManager {

  /// Downloads or fetches the cached PDF with a dynamic cache key.
   Future<File> downloadAndCachePDF(String url, String cacheKey) async {
    // Create a custom CacheManager with the dynamic cache key
    final cacheManager = CacheManager(
      Config(
        cacheKey, // Custom cache key passed as input
        stalePeriod: const Duration(days: 3), // Cache expiration period (3 days)
        maxNrOfCacheObjects: 100, // Max number of cache objects
      ),
    );

    try {

      final file = await cacheManager.getSingleFile(url);
      return _ensurePdfExtension(file);

    } catch (e) {
      print('Error downloading or fetching PDF: $e');
      rethrow;
    }
  }

  /// Ensures that the cached file has a `.pdf` extension.
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
