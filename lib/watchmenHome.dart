import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Login/login.dart';
import 'package:findany_flutter/Other/notification.dart';
import 'package:findany_flutter/groupchat/groupchathome.dart';
import 'package:findany_flutter/leaveforms/watchmenleavehome.dart';
import 'package:findany_flutter/universitynews/NewsList.dart';
import 'package:findany_flutter/Other/QandA.dart';
import 'package:findany_flutter/Other/review.dart';
import 'package:findany_flutter/materials/materialshome.dart';
import 'package:findany_flutter/navigation/navigationhome.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/useraccount/useraccount.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'leaveforms/lecturerleavehome.dart';

class Watchmenhome extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Watchmenhome> {
  Utils utils = new Utils();
  LoadingDialog loadingDialog = new LoadingDialog();
  SharedPreferences sharedPreferences = new SharedPreferences();
  NotificationService notificationService = new NotificationService();
  FireStoreService fireStoreService = new FireStoreService();
  FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  String? email = '', name = '', imageUrl = '';
  String? _announcementText;
  StreamSubscription<DatabaseEvent>? _announcementSubscription;

  rtdb.DatabaseReference chatRef = rtdb.FirebaseDatabase.instance.ref().child("chats");
  rtdb.DatabaseReference onlineUsersRef = rtdb.FirebaseDatabase.instance.ref().child("onlineUsers");

  @override
  void initState() {
    super.initState();
    loadData();
    requestPermission();
    _fetchAnnouncementText();
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
  }

  Future<void> _fetchAnnouncementText() async {
    final DatabaseReference announcementRef = _database.ref('Home');
    _announcementSubscription = announcementRef.onValue.listen((event) {
      if (!mounted) return;
      final DataSnapshot snapshot = event.snapshot;
      setState(() {
        _announcementText = snapshot.exists
            ? (snapshot.value as Map)['Announcement']
            : null;
        print("HOME : ${snapshot.value}");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Colors.greenAccent[700],
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationHome()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: FutureBuilder<void>(
          future: loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else {
              return Column(
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        UserAccountsDrawerHeader(
                          accountName: Text(name!),
                          accountEmail: Text(email!),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                          ),
                          currentAccountPicture: CircleAvatar(
                            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(imageUrl!) as ImageProvider<Object>?
                                : AssetImage('assets/images/defaultimage.png'),
                            backgroundColor: Colors.white,
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.person),
                          title: Text('Profile'),
                          onTap: () async {
                            if (await utils.checkInternetConnection()) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => UserAccount()),
                              );
                            } else {
                              utils.showToastMessage("Connect to the internet", context);
                            }
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.reviews),
                          title: Text('Reviews/Suggestions'),
                          onTap: () async {
                            if (await utils.checkInternetConnection()) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => Review()),
                              );
                            } else {
                              utils.showToastMessage("Connect to the internet", context);
                            }
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.question_answer),
                          title: Text('Q & A'),
                          onTap: () async {
                            if (await utils.checkInternetConnection()) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => QuestionAndAnswer()),
                              );
                            } else {
                              utils.showToastMessage("Connect to the internet", context);
                            }
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
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_announcementText != null && _announcementText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
                child: Linkify(
                  text: _announcementText!,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  linkStyle: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  onOpen: (link) async {
                    if (await canLaunch(link.url)) {
                      await launch(link.url);
                    } else {
                      throw 'Could not launch ${link.url}';
                    }
                  },
                ),
              ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  // _buildGridItem(
                  //   context,
                  //   'assets/images/groupchat.png',
                  //   'Let\'s Talk',
                  //   GroupChatHome(),
                  // ),
                  // _buildGridItem(
                  //   context,
                  //   'assets/images/xerox.png',
                  //   'Get Xerox',
                  //   XeroxHome(),
                  // ),
                  // _buildGridItem(
                  //   context,
                  //   'assets/images/materials.png',
                  //   'Materials',
                  //   MaterialsHome(),
                  // ),
                  _buildGridItem(
                    context,
                    'assets/images/navigation.png',
                    'Navigation',
                    MapScreen(),
                  ),
                  _buildGridItem(
                    context,
                    'assets/images/universitynews.jpeg',
                    'University News',
                    NewsListScreen(),
                  ),
                  // _buildGridItem(
                  //   context,
                  //   'assets/images/busbooking.png',
                  //   'Bus Booking',
                  //   BusBookingHome(),
                  // ),
                  _buildGridItem(
                      context,
                      'assets/images/LeaveForms.png',
                      'Leave Forms',
                      WatchmenLeavehome()
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildGridItem(BuildContext context, String imagePath, String title, Widget destination) {
    return GestureDetector(
      onTap: () async{
        if(await utils.checkInternetConnection()){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        }else{
          utils.showToastMessage("Connect to the internet", context);
        }

      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 80,
              height: 80,
            ),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadData() async {
    loadingDialog.showDefaultLoading("Getting Details...");
    DocumentReference documentReference = FirebaseFirestore.instance.doc('/UserDetails/${utils.getCurrentUserUID()}');
    email =await utils.getCurrentUserEmail();
    name = await sharedPreferences.getDataFromReference(documentReference, "Name") ?? '';
    imageUrl = await sharedPreferences.getDataFromReference(documentReference, 'ProfileImageURL') ?? '';

    utils.updateToken().then((value) {
      loadingDialog.dismiss();
    });

  }

  Future<void> signOut() async {
    if (!mounted) return;
    print("Singing out user in Home");
    loadingDialog.showDefaultLoading('Signing Out...');

    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().disconnect();
      utils.deleteFile('/data/data/com.neelam.FindAny/shared_prefs/FlutterSecureStorage.xml');
      utils.deleteFolder('/data/data/com.neelam.FindAny/cache/libCachedImageData');
      utils.deleteFolder('/data/data/com.neelam.FindAny/databases');

      if (mounted) {
        loadingDialog.dismiss();
        if(await utils.checkInternetConnection()){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
        }else{
          utils.showToastMessage("Connect to the internet", context);
        }
      }
    } catch (error) {
      print("Error signing out: $error");
      if (mounted) {
        loadingDialog.dismiss();
      }
    }
  }

  @override
  void dispose() {
    _announcementSubscription?.cancel();
    super.dispose();
    utils.deleteFolder("/data/data/com.neelam.FindAny/cache");
    loadingDialog.dismiss();
    print('Home Disposed');
  }
}
