import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:findany_flutter/Login/login.dart';
import 'package:findany_flutter/groupchat/universitychat.dart';
import 'package:findany_flutter/materials/materialshome.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/useraccount/useraccount.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:findany_flutter/xerox/xeroxhome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Home extends StatefulWidget{
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver{
  Utils utils = new Utils();
  LoadingDialog loadingDialog = new LoadingDialog();
  SharedPreferences sharedPreferences = new SharedPreferences();
  NotificationService notificationService = new NotificationService();
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? email='',name='',imageUrl='';

  @override
  void initState() {
    super.initState();
    loadData();
    requestPermission();
    utils.getToken();
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      drawer: Drawer(
        child: FutureBuilder<void>(
          future: loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else {
              print('ON drawer opened $imageUrl');
              return ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  UserAccountsDrawerHeader(
                    accountName: Text(name!),
                    accountEmail: null,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                    currentAccountPicture: CircleAvatar(
                      radius: 100,
                      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(imageUrl!) as ImageProvider<Object>?
                          : AssetImage('assets/images/defaultimage.png'),
                      backgroundColor: Colors.white, // Add a background color if needed
                    ),
                    otherAccountsPictures: [],
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Profile'),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => UserAccount()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.exit_to_app),
                    title: Text('Sign Out'),
                    onTap: () async {
                      if (await utils.checkInternetConnection()) {
                        signOut();
                      } else {
                        utils.showToastMessage('Check your internet connections', context);
                      }
                    },
                  ),
                ],
              );
            }
          },
        ),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UniversityChat()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/groupchat.jpg',
                        width: 100,
                        height: 100,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Lets Talk',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => XeroxHome()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/xerox.png',
                        width: 100,
                        height: 100,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Get Xerox',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20), // Add some space between the rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  // Add your functionality here
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MaterialsHome()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/materials.png', // Add your image path
                        width: 100,
                        height: 100,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Materials',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Add your functionality here
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Container( // White container
                        width: 100,
                        height: 100,
                        color: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Text(
                        '',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> loadData() async {
    loadingDialog.showDefaultLoading("Getting Details...");
    email = await sharedPreferences.getSecurePrefsValue('Email')?? '';
    name = await sharedPreferences.getSecurePrefsValue("Name") ??  '';
    imageUrl = await sharedPreferences.getSecurePrefsValue('ProfileImageURL')?? '';

    print('Home Page Loaded data: $email  $name  $imageUrl');
    utils.updateToken().then((value) {
      loadingDialog.dismiss();
    });
  }

  Future<void> signOut() async {
    if (mounted) {
      loadingDialog.showDefaultLoading('Signing Out...');
      try {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().disconnect();
        utils.deleteFile('/data/data/com.neelam.FindAny/shared_prefs/FlutterSecureStorage.xml');
        utils.deleteFolder('/data/data/com.neelam.FindAny/cache/libCachedImageData');
        loadingDialog.dismiss();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
      } catch (error) {
        print("Error signing out: $error");
        loadingDialog.dismiss();
      }
    } else {
      print('Unmounted singOut');
    }
  }

  @override
  void dispose(){
    super.dispose();
    utils.deleteFolder("/data/data/com.neelam.FindAny/cache");
    print('Home Disposed');
  }
}
