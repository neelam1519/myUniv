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
    return Scaffold(
      appBar: AppBar(
        title: Text('User Account'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: EdgeInsets.only(top: kToolbarHeight - 40),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {
                print('Edit Profile');
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
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.image,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),
          FutureBuilder<void>(
            future: getUserDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                return Column(
                  children: [
                    Text(
                      '${name ?? ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${regNo ?? ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    // Add more Text widgets for other details like email if needed
                  ],
                );
              }
            },
          ),
          SizedBox(height: 20),
          Divider(height: 1, color: Colors.black),
          SizedBox(height: 20),
          Column(
            children: [
              Visibility(
                visible: showAcademicDetails,
                child: ListTile(
                  title: Text('Personal details'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                  },
                ),
              ),
              Visibility(
                visible: showFacultyDetails,
                child: ListTile(
                  title: Text('Faculty details'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {

                  },
                ),
              ),
              Visibility(
                visible: showPersonalDetails,
                child: ListTile(
                  title: Text('Academic details'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {

                  },
                ),
              ),
              Visibility(
                visible: showHostelDetails,
                child: ListTile(
                  title: Text('Hostel details'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {

                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> getUserDetails() async {
    name = await sharedPreferences.getSecurePrefsValue('Name');
    regNo = await sharedPreferences.getSecurePrefsValue('Registration Number');
    imageUrl = await sharedPreferences.getSecurePrefsValue('ProfileImageURL');
    print('ImageUrl: $imageUrl');
  }
}
