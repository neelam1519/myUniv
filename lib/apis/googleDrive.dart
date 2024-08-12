import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class GoogleDriveService {
  final _scopes = [drive.DriveApi.driveScope];

  Future<drive.DriveApi> _getDriveApi() async {
    try {
      // Load the service account credentials
      final credentials = await rootBundle.loadString('assets/googleDrive.json');
      final accountCredentials = ServiceAccountCredentials.fromJson(json.decode(credentials));

      // Authenticate using the service account credentials
      final authClient = await clientViaServiceAccount(accountCredentials, _scopes);
      return drive.DriveApi(authClient);
    } catch (e) {
      print('Error getting Drive API client: $e');
      rethrow;  // Re-throwing to allow calling functions to handle it
    }
  }

  Future<List<drive.File>> listFiles(String folderId) async {
    try {
      final driveApi = await _getDriveApi();
      print('Fetching files from folder ID: $folderId');
      final fileList = await driveApi.files.list(
          q: "'$folderId' in parents",
          $fields: "files(id, name)"
      );
      print('File List Response: ${fileList.files}');
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        print('Files found:');
        for (var file in fileList.files!) {
          print('Name: ${file.name}, ID: ${file.id}');
        }
      } else {
        print('No files found in the folder.');
      }
      return fileList.files ?? [];
    } catch (e) {
      print('Error retrieving file list: $e');
      return [];
    }
  }

  Future<String?> getAccountEmail() async {
    try {
      final driveApi = await _getDriveApi();
      final about = await driveApi.about.get($fields: 'user/emailAddress');
      print('Account Email: ${about.user?.emailAddress}');
      return about.user?.emailAddress;
    } catch (e) {
      print('Error retrieving account email: $e');
      return null;
    }
  }

  Future<void> uploadFile(String folderId, String filePath) async {
    try {
      final driveApi = await _getDriveApi();

      var file = drive.File();
      file.parents = [folderId];
      file.name = filePath.split('/').last;

      var fileContent = File(filePath).openRead();
      var media = drive.Media(fileContent, File(filePath).lengthSync());

      var response = await driveApi.files.create(file, uploadMedia: media);

      print('File uploaded: ${response.name}, ID: ${response.id}');
    } catch (e) {
      print('Error uploading file: $e');
    }
  }
}
