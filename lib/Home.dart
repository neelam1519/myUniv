import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Login/login.dart';
import 'package:findany_flutter/Other/NewsList.dart';
import 'package:findany_flutter/Other/QandA.dart';
import 'package:findany_flutter/Other/review.dart';
import 'package:findany_flutter/groupchat/universitychat.dart';
import 'package:findany_flutter/materials/materialshome.dart';
import 'package:findany_flutter/navigation/navigationhome.dart';
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

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  Utils utils = new Utils();
  LoadingDialog loadingDialog = new LoadingDialog();
  SharedPreferences sharedPreferences = new SharedPreferences();
  NotificationService notificationService = new NotificationService();
  FireStoreService fireStoreService = new FireStoreService();
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? email = '', name = '', imageUrl = '';

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
        backgroundColor: Colors.greenAccent[700],
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active),
            onPressed: () {

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
              return ListView(
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
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => UserAccount()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.reviews),
                    title: Text('Reviews'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Review()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.question_answer),
                    title: Text('Q & A'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => QuestionAndAnswer()),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildGridItem(
              context,
              'assets/images/groupchat.png',
              'Let\'s Talk',
              UniversityChat(),
            ),
            _buildGridItem(
              context,
              'assets/images/xerox.png',
              'Get Xerox',
              XeroxHome(),
            ),
            _buildGridItem(
              context,
              'assets/images/materials.png',
              'Materials',
              MaterialsHome(),
            ),
            _buildGridItem(
              context,
              'assets/images/navigation.jpeg',
              'Navigation',
              MapScreen(),
            ),
            _buildGridItem(
              context,
              'assets/images/universitynews.jpeg',
              'University News',
              NewsListScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String imagePath, String title, Widget destination) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
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
    email = await sharedPreferences.getDataFromReference(documentReference, 'Email') ?? '';
    name = await sharedPreferences.getDataFromReference(documentReference, "Name") ?? '';
    imageUrl = await sharedPreferences.getDataFromReference(documentReference, 'ProfileImageURL') ?? '';

    utils.updateToken().then((value) {
      loadingDialog.dismiss();
    });
    print('Home Page Loaded data: $email  $name  $imageUrl');
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
  void dispose() {
    super.dispose();
    utils.deleteFolder("/data/data/com.neelam.FindAny/cache");
    print('Home Disposed');
  }
}
