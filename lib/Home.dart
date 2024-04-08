import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:findany_flutter/Login/login.dart';
import 'package:findany_flutter/groupchat/groupchathome.dart';
import 'package:findany_flutter/useraccount/useraccount.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:findany_flutter/xerox/xeroxhome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Home extends StatefulWidget {

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Utils utils = new Utils();
  LoadingDialog loadingDialog = new LoadingDialog();
  SharedPreferences sharedPreferences = new SharedPreferences();
  FirebaseAuth auth = FirebaseAuth.instance;
  User? currentUser;

  String? email='',name='',imageUrl='';

  @override
  void initState() {
    super.initState();
    currentUser = auth.currentUser;
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Home')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(name!),
              accountEmail: null,
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              currentAccountPicture: CircleAvatar(
                radius: 80,
                backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(imageUrl!) as ImageProvider<Object>?
                    : AssetImage('assets/white paper.png'),
                backgroundColor: Colors.white, // Add a background color if needed
              ),
              otherAccountsPictures: [],
            ),

            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserAccount()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Sign Out'),
              onTap: () {
                signOut();
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GroupChatHome()),
                );              },
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
      ),
    );
  }

  Future<void> loadData() async {
    loadingDialog.showDefaultLoading("Getting Details...");
    email = await sharedPreferences.getSecurePrefsValue('Email')?? '';
    name = await sharedPreferences.getSecurePrefsValue("Name") ??  '';
    imageUrl = await sharedPreferences.getSecurePrefsValue('ProfileImageURL')?? '';

    print('$email  $name  $imageUrl');
    EasyLoading.dismiss().then((value){
      setState(() {});
    });
  }

  Future<void> signOut() async {
    if (mounted) {
      loadingDialog.showDefaultLoading('Signing Out...');
      try {

        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().disconnect();
        utils.deleteFolder('/data/data/com.neelam.FindAny/shared_prefs');
        utils.deleteFolder('/data/data/com.neelam.FindAny/cache/libCachedImageData');
        EasyLoading.dismiss();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
      } catch (error) {
        print("Error signing out: $error");
        EasyLoading.dismiss();
      }
    }else{
      print('Unmounted singOut');
    }
  }

}
