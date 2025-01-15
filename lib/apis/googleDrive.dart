import 'package:findany_flutter/services/cachemanager.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class GoogleDriveService {
  late drive.DriveApi _driveApi;
  CustomCacheManager cacheManager = CustomCacheManager();

  Future<void> authenticate() async {
    try {
      // Load credentials from the JSON file
      String credentials = await _loadCredentials();
      print("Credentials loaded successfully.");

      final accountCredentials = ServiceAccountCredentials.fromJson(credentials);
      final scopes = [drive.DriveApi.driveScope];

      // Authenticate and initialize _driveApi
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      _driveApi = drive.DriveApi(client);
      print("Authentication successful.");
    } catch (e) {
      print("Error during authentication: $e");
    }
  }

  Future<String> _loadCredentials() async {
    try {
      // Load the service account credentials from the assets
      String credentials = await rootBundle.loadString('assets/findany-84c36-b2a3e1d26731.json');
      print("Credentials file loaded from assets.");
      return credentials;
    } catch (e) {
      print("Error loading credentials: $e");
      rethrow; // Rethrow the error to handle it in the calling function
    }
  }

  Future<List<drive.File>> listFoldersInFolder(String folderId) async {
    try {
      print("Listing folders inside folder with ID: $folderId");

      // Query for folders inside the specified folder by its ID
      final fileList = await _driveApi.files.list(
        q: "'$folderId' in parents and mimeType='application/vnd.google-apps.folder'", // Filter by folder type
        $fields: "files(id, name)", // Specify the fields to return
      );

      // Check if any folders were found
      if (fileList.files == null || fileList.files!.isEmpty) {
        print("No folders found inside the specified folder.");
        return [];
      }

      // Print the folders found for debugging
      print("Folders found inside folder:");
      for (var folder in fileList.files!) {
        print("Folder ID: ${folder.id}, Folder Name: ${folder.name}");
      }

      // Return the list of folders found
      return fileList.files!;
    } catch (e) {
      print("An error occurred while listing folders: $e");
      return [];
    }
  }

  Stream<File> listFilesInFolderWithCache(String folderId) async* {
    try {
      print("Listing files in folder with ID: $folderId");

      // Fetch the list of files in the folder
      final fileList = await _driveApi.files.list(
        q: "'$folderId' in parents and mimeType != 'application/vnd.google-apps.folder'",
        $fields: "files(id, name, webContentLink)",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        print("No files found in folder.");
        return;
      }

      print("Files found in folder:");

      for (var file in fileList.files!) {
        final fileName = file.name ?? "unknown_file";
        final fileUrl = file.webContentLink;

        print("Processing File: $fileName");

        if (fileUrl != null) {
          final cachedFile = await cacheManager.downloadAndCachePDF(fileUrl, fileName);
          print("File cached: ${cachedFile.path}");
          yield cachedFile; // Emit the cached file immediately
        } else {
          print("Skipping file $fileName (no download link).");
        }
      }
    } catch (e) {
      print("An error occurred while listing files: $e");
      rethrow;
    }
  }
}
