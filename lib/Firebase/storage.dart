import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseStorageHelper {
  FirebaseStorage storage = FirebaseStorage.instance;

  Future<String> getCachePath(String storagePath) async {
    Directory cacheDir = await getTemporaryDirectory();
    return '${cacheDir.path}/$storagePath'.replaceAll(' ', '');
  }

  Future<int> getFileCount(String folderPath) async {
    int fileCount = 0;
    try {
      ListResult listResult = await storage.ref(folderPath).listAll();
      fileCount = listResult.items.length;
      return fileCount;
    } catch (e) {
      print('Error getting file count: $e');
      return 0;
    }
  }

  Future<List<String>> getFileNames(String storagePath) async {
    final result = await storage.ref(storagePath).listAll();
    return result.items.map((ref) => ref.name).toList();
  }

  Future<String> uploadXeroxFiles(String fileName, File file) async {
    try {
      // Create a reference to the location where you want to upload the file
      final Reference storageReference =
          storage.ref().child('XeroxFiles/$fileName');

      // Upload the file
      final UploadTask uploadTask = storageReference.putFile(file);

      // Wait until the file is uploaded
      await uploadTask.whenComplete(() => null);

      // Get the download URL of the uploaded file
      final String downloadUrl = await storageReference.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

// Helper method to upload a single file to Firebase Storage
  Future<String> uploadFile(File file, String filePath, String fileName) async {
    try {
      print('File: ${file.toString()}');
      print('File Path: $filePath');
      print('File Name: $fileName');

      // Get a reference to the file location (including the folder path)
      Reference storageRef =
          FirebaseStorage.instance.ref().child(filePath).child(fileName);

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(file);

      // Listen for state changes, errors, and completion of the upload task
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload task state: ${snapshot.state}');
        if (snapshot.state == TaskState.running) {
          print('Upload task in progress');
        } else if (snapshot.state == TaskState.success) {
          print('Upload task completed successfully');
        }
      }, onError: (error) {
        print('Upload task error: $error');
      });

      // Wait for the upload task to complete
      TaskSnapshot taskSnapshot = await uploadTask;
      print('TaskSnapshot: $taskSnapshot');

      // Retrieve the download URL
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      print('File uploaded successfully. Download URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return '';
    }
  }

  Future<File?> downloadFile(String fullPath, String localDirectory) async {
    try {
      // Get a reference to the file in Firebase Storage
      Reference ref = storage.ref(fullPath);
      String fileName = ref.name;

      // Ensure the local directory exists, and create it if it doesn't
      await Directory(localDirectory).create(recursive: true);

      // Construct the full local file path by combining the directory with the file name
      String filePath = '$localDirectory/$fileName';
      File localFile = File(filePath);

      print("Downloading File: $fullPath");
      // Download the file from Firebase Storage and save it locally
      await ref.writeToFile(localFile);

      print('File downloaded to: ${localFile.path}');
      return localFile;
    } on FirebaseException catch (e) {
      print('Firebase error downloading file: $e');
      return null;
    } catch (e) {
      print('General error downloading file: $e');
      return null;
    }
  }

  Future<void> deleteFile(String filePath) async {
    try {
      // Create a reference to the file to be deleted
      Reference fileRef = storage.ref().child(filePath);

      // Delete the file
      await fileRef.delete();

      print('File deleted successfully from path: $filePath');
    } catch (e) {
      print('Failed to delete file: $e');
      rethrow;
    }
  }

  // Method to delete a folder and its contents
  Future<void> deleteFolder(String folderPath) async {
    try {
      // List all files and subfolders in the folder
      final ListResult result = await storage.ref(folderPath).listAll();

      // Delete all files in the folder
      for (Reference ref in result.items) {
        await ref.delete();
      }

      // Recursively delete subfolders
      for (Reference ref in result.prefixes) {
        await deleteFolder(ref.fullPath);
      }
    } catch (e) {
      print('Error deleting folder: $e');
    }
  }
}
