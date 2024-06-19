import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:findany_flutter/Home.dart';
import 'package:findany_flutter/useraccount/academicdetails.dart';
import 'package:findany_flutter/useraccount/personalDetails.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import '../utils/sharedpreferences.dart';
import '../utils/utils.dart';

class UserAccount extends StatefulWidget {
  @override
  _UserAccountState createState() => _UserAccountState();
}

class _UserAccountState extends State<UserAccount> {
  Utils utils = Utils();
  SharedPreferences sharedPreferences = SharedPreferences();
  FireStoreService firebaseService = FireStoreService();
  LoadingDialog loadingDialog = new LoadingDialog();

  String? name, regNo, email, imageUrl;

  bool showPersonalDetails = true;
  bool showAcademicDetails = true;
  bool showHostelDetails = true;
  bool showFacultyDetails = true;

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
        return true; // Return true to allow back button press
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('User Account'),
        ),
        body: FutureBuilder<void>(
          future: getUserDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: kToolbarHeight - 40),
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () async {
                          print('Edit Profile');
                          if (await utils.checkInternetConnection()) {
                            pickFile();
                          } else {
                            utils.showToastMessage('Check your internet connection', context);
                          }
                        },
                        child: Stack(
                          children: [
                            ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: imageUrl ?? '',
                                placeholder: (context, url) => CircularProgressIndicator(),
                                errorWidget: (context, url, error) => Icon(Icons.error),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Positioned(
                            //   bottom: 0,
                            //   right: 0,
                            //   child: Container(
                            //     padding: EdgeInsets.all(6),
                            //     decoration: BoxDecoration(
                            //       color: Colors.black,
                            //       shape: BoxShape.circle,
                            //     ),
                            //     child: Icon(
                            //       Icons.image,
                            //       color: Colors.white,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('${name ?? ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      '${regNo ?? ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                    SizedBox(height: 20),
                    Divider(height: 1, color: Colors.grey),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Visibility(
                          visible: showPersonalDetails,
                          child: ListTile(
                            title: Text('Personal details', style: TextStyle(fontSize: 16)),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PersonalDetails()),
                              );
                            },
                          ),
                        ),
                        Visibility(
                          visible: showAcademicDetails,
                          child: ListTile(
                            title: Text('Academic details', style: TextStyle(fontSize: 16)),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AcademicDetails()),
                              );                            },
                          ),
                        ),
                        // Visibility(
                        //   visible: showFacultyDetails,
                        //   child: ListTile(
                        //     title: Text('Faculty details', style: TextStyle(fontSize: 16)),
                        //     trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        //     onTap: () {
                        //       utils.showToastMessage('Under Development', context);
                        //     },
                        //   ),
                        // ),
                        // Visibility(
                        //   visible: showHostelDetails,
                        //   child: ListTile(
                        //     title: Text('Hostel details', style: TextStyle(fontSize: 16)),
                        //     trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        //     onTap: () {
                        //       utils.showToastMessage('Under Development', context);
                        //     },
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      print('Result: $result');
      if (result != null) {
        print('Paths: ${result.paths}');
        List<String?> paths = result.paths;
        if (paths.isNotEmpty) {
          String? imagePath = paths[0];
          print('Image Path: $imagePath');

          await uploadImageAndStoreUrl(imagePath);
        }
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  Future<void> uploadImageAndStoreUrl(String? imagePath) async {
    loadingDialog.showDefaultLoading('Updating profile');
    try {
      if (imagePath != null) {
        String extension = utils.getFileExtension(File(imagePath));
        Reference ref = _storage.ref().child('ProfileImages').child('${utils.getCurrentUserUID()}.$extension');
        final UploadTask uploadTask = ref.putFile(File(imagePath));
        final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        print('Download URL: $downloadUrl');

        final Map<String, String> image = {'ProfileImageURL': downloadUrl};
        await sharedPreferences.storeMapValuesInSecureStorage(image);

        DocumentReference userRef = FirebaseFirestore.instance.doc('UserDetails/${utils.getCurrentUserUID()}');
        firebaseService.uploadMapDataToFirestore(image, userRef);
        setState(() {});
      }
      loadingDialog.dismiss();
    } catch (e) {
      print('Error uploading file and storing URL: $e');
      loadingDialog.dismiss();
    }
  }

  Future<void> getUserDetails() async {
    name = await sharedPreferences.getSecurePrefsValue('Name');
    regNo = await sharedPreferences.getSecurePrefsValue('Registration Number');
    imageUrl = await sharedPreferences.getSecurePrefsValue('ProfileImageURL');
    print('Profile ImageUrl: $imageUrl');
  }
}
