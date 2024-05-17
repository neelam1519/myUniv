import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:path_provider/path_provider.dart';

class Utils{

  FirebaseAuth auth = FirebaseAuth.instance;
  FireStoreService fireStoreService = new FireStoreService();

  Future<void> clearCache() async {
    Directory cacheDir = await getTemporaryDirectory();
    Directory targetDir = Directory('${cacheDir.path}/FileSelection/');

    if (await targetDir.exists()) {
      await targetDir.delete(recursive: true);
      print('Cache cleared in ${targetDir.path}');
    } else {
      print('Cache directory ${targetDir.path} does not exist.');
    }
  }

  bool isURL(String str) {
    RegExp urlRegex = RegExp(
        r'^(?:http|https):\/\/'
        r'(?:www\.)?'
        r'(?:(?:[A-Z0-9][A-Z0-9-]{0,61}[A-Z0-9]\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|'
        r'localhost|'
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
        r'(?::\d+)?'
        r'(?:\/?[^\s\/]*)*\/?'
        r'(?:\?[^\s]*)?'
        r'(?:#[^\s]*)?$',
        caseSensitive: false);

    return urlRegex.hasMatch(str);
  }

  Future<void> showToastMessage(String message, BuildContext context) async {
    showToast(
      message,
      context: context,
      animation: StyledToastAnimation.slideFromBottom,
      reverseAnimation: StyledToastAnimation.slideToBottom,
      position: StyledToastPosition.bottom,
      animDuration: Duration(milliseconds: 400),
      duration: Duration(seconds: 2),
      curve: Curves.elasticOut,
      reverseCurve: Curves.elasticIn,
    );
  }

  String getCurrentUserUID() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      return "";
    }
  }

  Future<String?> getCurrentUserEmail() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user != null) {
      // User is signed in
      return user.email;
    } else {
      // No user is signed in
      return null;
    }
  }

  Future<String?> getCurrentUserDisplayName() async {
    try {
      User? user = auth.currentUser;
      if (user != null) {
        print('Current user Name: ${auth.currentUser}');
        return user.displayName;
      } else {
        return null; // No user signed in
      }
    } catch (e) {
      print('Error getting user display name: $e');
      return null;
    }
  }

  Future<void> deleteFileInCache(String filePath) async {
    try {
      File fileToDelete = File(filePath);
      await fileToDelete.delete();
      print("File is successfully deleted");
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

    Future<void> deleteFolder(String folderPath) async {
    print('Deleting Cache Folder');
      try {
        Directory folder = Directory(folderPath);
        if (await folder.exists()) {
          await folder.delete(recursive: true);
          print('Folder deleted: $folderPath');
        } else {
          print('Folder not found: $folderPath');
        }
      } catch (e) {
        print('Error deleting folder: $e');
      }
    }

    bool isValidMobileNumber(String mobileNumber) {
      RegExp regExp = RegExp(r'^[0-9]{10}$');
      return regExp.hasMatch(mobileNumber);
    }


  String getTodayDate() {
    DateTime now = DateTime.now();
    int day = now.day;
    int month = now.month;
    int year = now.year;

    String formattedDate = '$day/${month.toString().padLeft(2, '0')}/$year';

    return formattedDate;
  }


  Future<void> deleteFile(String filePath) async {
    try {
      // Check if the file exists
      if (await File(filePath).exists()) {
        // Delete the file
        await File(filePath).delete();
        print('File deleted successfully: $filePath');
      } else {
        print('File not found: $filePath');
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  String getFileExtension(File file) {
    String filePath = file.path;
    String extension = path.extension(filePath);
    if (extension.isNotEmpty && extension.startsWith('.')) {
      extension = extension.substring(1);
    }
    return extension;
  }

  Future<void> signOut() async{
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().disconnect(); // Disconnect Google Sign-In
  }

  String removeTextAfterFirstNumber(String input) {
    List<String> characters = input.split('');

    int indexOfNumber = characters.indexWhere((char) => RegExp(r'[0-9]').hasMatch(char));

    if (indexOfNumber != -1) {
      return input.substring(0, indexOfNumber).trim();
    } else {
      return input.trim();
    }
  }

  String removeEmailDomain(String email) {
    List<String> parts = email.split('@');

    if (parts.length == 2) {
      return parts[0];
    } else {
      return email;
    }
  }

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    bool isConnected = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);

    print('Connected to: ${_getConnectionType(connectivityResult)}');

    return isConnected;
  }

  String _getConnectionType(List<ConnectivityResult> connectivityResult) {
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      return 'Mobile data';
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else {
      return 'No network';
    }
  }

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  Future<String?> getToken() async {
    String? token = await firebaseMessaging.getToken();
    if (token != null) {
      print('Token: $token');
      return token;
    } else {
      print('Failed to get token.');
      return 'no Token';
    }
  }

  Future<void> openFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (error) {
      print('Error opening file: $error');
    }
  }

  Future<List<PlatformFile>?> pickMultipleFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx'],
      );
      return result?.files;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }




  Future<void> updateToken() async{
    // Listen for token refresh event
    FirebaseMessaging.instance.onTokenRefresh
        .listen((fcmToken) async {
      print('Updated Token: $fcmToken');
      String? email = await getCurrentUserEmail();
      String regNo = removeEmailDomain(email!);
      DocumentReference tokenRef = FirebaseFirestore.instance.doc('Tokens/Tokens');
      fireStoreService.uploadMapDataToFirestore({regNo:fcmToken}, tokenRef);
    }).onError((err) {
      // Error getting token.
      print('Error while refreshing token');
    });

  }

  String getMimeType(String extension) {
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      case '.ppt':
      case '.pptx':
        return 'application/vnd.ms-powerpoint';
      case '.txt':
        return 'text/plain';
      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/x-rar-compressed';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      default:
        return '*/*';
    }
  }


}