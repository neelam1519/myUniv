import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseStorageHelper {
  FirebaseStorage storage = FirebaseStorage.instance;

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

  Future<List<String>> getFileNames(String folderPath) async {
    List<String> fileNames = [];
    try {
      ListResult listResult = await storage.ref(folderPath).listAll();
      listResult.items.forEach((Reference ref) {
        fileNames.add(ref.name);
      });
      return fileNames;
    } catch (e) {
      print('Error getting file names: $e');
      return [];
    }
  }

  Future<String> uploadFile(File file, String folderName, String fileName) async {
    try {
      print('File: ${file.toString()}');
      print('Folder Name: ${folderName}');
      print('File Name: ${fileName.toString()}');

      // Get a reference to the file location (including the folder path)
      Reference storageRef = storage.ref().child(folderName).child(fileName);

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

  Future<File?> downloadFile(String fullPath) async {
    try {
      Reference ref = storage.ref(fullPath);
      String fileName = ref.name;
      print('Downloading file: $fileName');

      Directory cacheDir = await getTemporaryDirectory();
      String cachePath = '${cacheDir.path}/${fullPath.replaceAll(' ', '')}';
      print('Download Cache1: $cachePath');
      String cacheDirPath = cachePath.substring(0, cachePath.lastIndexOf('/'));

      await Directory(cacheDirPath).create(recursive: true);

      File tempFile = File(cachePath);
      await ref.writeToFile(tempFile);

      print('File downloaded to: ${tempFile.path}');
      return tempFile;
    } on FirebaseException catch (e) {
      print('Error downloading file: $e');
      return null;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

}
