import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Login/login.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Utils {
  FirebaseAuth auth = FirebaseAuth.instance;
  FireStoreService fireStoreService = FireStoreService();
  LoadingDialog loadingDialog = LoadingDialog();

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

  Future<void> showToastMessage(String message) async {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT, // or Toast.LENGTH_LONG
        gravity:
            ToastGravity.BOTTOM, // or ToastGravity.CENTER, ToastGravity.TOP
        timeInSecForIosWeb: 1, // duration in seconds for iOS and Web
        backgroundColor: Colors.black54, // background color of the toast
        textColor: Colors.white, // text color of the toast
        fontSize: 16.0 // text size
        );
  }

  Future<String?> getCurrentUserUID() async {
    String? email = await getCurrentUserEmail();
    final url = Uri.parse(
        'https://us-central1-findany-84c36.cloudfunctions.net/getUidByEmail?email=$email');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['uid'];
      } else {
        print('Error fetching UID: ${response.reasonPhrase}');
        return null;
      }
    } catch (error) {
      print('Error fetching UID: $error');
      return null;
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
      final directory = Directory(folderPath);
      if (await directory.exists()) {
        // Recursively delete the directory and its contents
        await directory.delete(recursive: true);
      } else {
        print('Directory does not exist');
      }
    } catch (e) {
      print('Error deleting directory: $e');
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

  Future<void> signOut(BuildContext context) async {
    GoogleSignIn googleSignIn = GoogleSignIn();
    loadingDialog.showDefaultLoading("Signing out...");
    await FirebaseAuth.instance.signOut();
    print('Successfully signed out from FirebaseAuth.');
    try {
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
        print('Successfully disconnected from Google Sign-In.');
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      print('Error during sign-out: $e');
    }
    await googleSignIn.signOut();
    loadingDialog.dismiss();
  }

  String removeTextAfterFirstNumber(String input) {
    List<String> characters = input.split('');

    int indexOfNumber =
        characters.indexWhere((char) => RegExp(r'[0-9]').hasMatch(char));

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
    try {
      String? token = await firebaseMessaging.getToken();
      print('Token: $token');
      return token;
    } catch (e) {
      print('Error retrieving token: $e');
      return null;
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

  Future<void> updateToken() async {
    // Listen for token refresh event
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      print('Updated Token: $fcmToken');
      String? email = await getCurrentUserEmail();
      String regNo = removeEmailDomain(email!);
      DocumentReference tokenRef =
          FirebaseFirestore.instance.doc('Tokens/Tokens');
      fireStoreService.uploadMapDataToFirestore({regNo: fcmToken}, tokenRef);
    }).onError((err) {
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

  Future<List<String>> getAdmins(DocumentReference specificRef) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference adminRef = firestore.doc('AdminDetails/All');

    Map<String, dynamic>? specificAdmins =
        await fireStoreService.getDocumentDetails(specificRef);
    Map<String, dynamic>? mainAdmins =
        await fireStoreService.getDocumentDetails(adminRef);

    List<String> admins = [];
    admins.addAll(specificAdmins!.values.cast<String>());
    admins.addAll(mainAdmins!.values.cast<String>());
    print('Admins: $admins');
    return admins;
  }

  Future<List<String>> getSpecificTokens(DocumentReference specificRef) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference adminRef = firestore.doc('AdminDetails/All');
    DocumentReference tokenRef = firestore.doc('Tokens/Tokens');

    Map<String, dynamic>? specificAdmins =
        await fireStoreService.getDocumentDetails(specificRef);
    Map<String, dynamic>? mainAdmins =
        await fireStoreService.getDocumentDetails(adminRef);

    List<String> admins = [];
    List<String> tokens = [];

    admins.addAll(specificAdmins!.values.cast<String>());
    admins.addAll(mainAdmins!.values.cast<String>());
    print('Admin Names: $admins');

    if (admins.isNotEmpty) {
      Map<String, dynamic>? tokenValues =
          await fireStoreService.getDocumentDetails(tokenRef);
      for (String admin in admins) {
        if (tokenValues!.containsKey(admin)) {
          tokens.add(tokenValues[admin]);
        }
      }
    }

    print('Admin Names: $admins');
    print('Admin Tokens: $tokens');

    return tokens;
  }

  Future<List<String>> getAllTokens() async {
    print("Getting ALL tokens");
    DocumentReference tokenRef =
        FirebaseFirestore.instance.doc('Tokens/Tokens');

    try {
      Map<String, dynamic>? allTokens =
          await fireStoreService.getDocumentDetails(tokenRef);

      List<String> tokens =
          allTokens!.values.map((token) => token.toString()).toList();

      // String? currentToken = await getToken();
      //
      // if (currentToken != null && tokens.contains(currentToken)) {
      //   tokens.remove(currentToken);
      // }

      print('Filtered Tokens: $tokens');
      return tokens;
    } catch (e) {
      print('Error fetching tokens: $e');
      return [];
    }
  }

  bool isFileImage(File file) {
    final List<String> imageExtensions = ['png', 'jpg', 'jpeg', 'gif'];
    String extension = getFileExtension(file).toLowerCase();
    return imageExtensions.contains(extension);
  }

  bool isFilePdf(File file) {
    return getFileExtension(file).toLowerCase() == 'pdf';
  }

  bool isMediaImage(ChatMedia media) {
    final List<String> imageExtensions = ['png', 'jpg', 'jpeg', 'gif'];
    String extension = getMediaExtension(media.url).toLowerCase();
    return imageExtensions.contains(extension);
  }

  bool isMediaPdf(ChatMedia media) {
    return getMediaExtension(media.url).toLowerCase() == 'pdf';
  }

  String getMediaExtension(String url) {
    return path.extension(url).replaceAll('.', '');
  }

  Future<String?> getCurrentUserProfileImage() async {
    try {
      User? user = auth.currentUser;
      if (user != null && user.photoURL != null) {
        return user.photoURL;
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user profile image URL: $e');
      return null;
    }
  }

  Future<bool> checkFirstTime(String key) async {
    SharedPreferences sharedPreferences = SharedPreferences();
    String? isFirstTime = await sharedPreferences.getSecurePrefsValue(key);

    bool value = true;

    // Check if the stored value is 'false' (as a string)
    if (isFirstTime!.toLowerCase() == 'false') {
      value = false;
    }

    print('checkFirstTime: $value');
    return value;
  }

  Future<File> downloadFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = path.join(directory.path, fileName);

    final File file = File(filePath);

    final http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to download file');
    }

    return file;
  }

  double calculatePages(int numberOfFiles, int pagesPerFile) {
    return (numberOfFiles * pagesPerFile).toDouble();
  }

  String getCurrentTime() {
    // Get the current UTC time
    DateTime now = DateTime.now().toUtc();

    // Convert UTC time to Indian Standard Time (UTC+5:30)
    DateTime istTime = now.add(const Duration(hours: 5, minutes: 30));

    // Format the time to a readable string
    String formattedTime =
        "${istTime.hour}:${istTime.minute.toString().padLeft(2, '0')}:${istTime.second.toString().padLeft(2, '0')}";

    return formattedTime;
  }

// Future<void> sendSMS(String message, String recipient) async {
  //   final url = Uri.parse('https://www.fast2sms.com/dev/bulkV2');
  //
  //   // Headers
  //   final headers = {
  //     'authorization': 'Kkt6bmG7ejlnpJAfC6Gut6fxJR3WU2uUneDZjKZSXi7FUAP1VQDdVPZbS230',
  //     'Content-Type': 'application/json'
  //   };
  //
  //   // Body
  //   final body = jsonEncode({
  //     'route': 'q',
  //     'sender_id': 'FindAny',
  //     'message': message,
  //     'language': 'english',
  //     'flash': 0,
  //     'numbers': recipient
  //   });
  //
  //   try {
  //     final response = await http.post(url, headers: headers, body: body);
  //
  //     if (response.statusCode == 200) {
  //       final responseData = jsonDecode(response.body);
  //       print('Response Data: $responseData');
  //       if (responseData['return']) {
  //         print('SMS sent successfully');
  //       } else {
  //         print('Failed to send SMS: ${responseData['message']}');
  //       }
  //     } else {
  //       print('Failed to send SMS: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Error sending SMS: $e');
  //   }
  // }
}
