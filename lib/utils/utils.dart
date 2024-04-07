import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:path_provider/path_provider.dart';

class Utils{

  FirebaseAuth auth = FirebaseAuth.instance;

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
      // The user is logged in
      return user.uid;
    } else {
      // No user is logged in
      return ""; // Return an empty string or null to indicate no user is logged in
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
      // Regular expression for a valid mobile number
      // Assumes a 10-digit number without any formatting characters
      RegExp regExp = RegExp(r'^[0-9]{10}$');

      // Check if the mobile number matches the regular expression
      return regExp.hasMatch(mobileNumber);
    }


  String getTodayDate() {
    DateTime now = DateTime.now();
    int day = now.day;
    int month = now.month;
    int year = now.year;

    // Formatting the date in desired format (dd/mm/yyyy)
    String formattedDate = '$day/${month.toString().padLeft(2, '0')}/$year';

    return formattedDate;
  }

  String getFileExtension(File file) {
    // Get the file path from the File object
    String filePath = file.path;

    // Extract the file extension using the extension method from the path package
    String extension = path.extension(filePath);

    // Remove the dot (.) from the extension if present
    if (extension.isNotEmpty && extension.startsWith('.')) {
      extension = extension.substring(1);
    }

    return extension;
  }
}