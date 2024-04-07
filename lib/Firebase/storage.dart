import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageHelper {
  FirebaseStorage storage = FirebaseStorage.instance;

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
}
