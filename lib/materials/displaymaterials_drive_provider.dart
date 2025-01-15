import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../apis/googleDrive.dart';
import '../services/cachemanager.dart';
import '../apis/googleDrive.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class PDFProvider with ChangeNotifier {
  List<MaterialsPDFModel> _materials = [];
  int? totalpdfCount;

  List<MaterialsPDFModel> get materials => _materials;

  final FireStoreService fireStoreService = FireStoreService();
  GoogleDriveService driveService = GoogleDriveService();

  Future<void> getPdfList(String unitID) async {
    try {
      _materials.clear();

      await driveService.authenticate();

      Stream<File> folders = await driveService.listFilesInFolderWithCache(unitID);


    } catch (e) {
      print('Error fetching PDFs: $e');
      _materials = []; // Handle errors by setting materials to an empty list
      notifyListeners();
    }
  }




   void clearMaterials() {
      _materials = [];
      totalpdfCount = null; // Reset the total count
      notifyListeners();
    }

}

class MaterialsPDFModel {
  final String filename;
  String? localPath;

  MaterialsPDFModel({required this.filename, required this.localPath});
}
