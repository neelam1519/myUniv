import 'package:findany_flutter/Login/login.dart';
import 'package:findany_flutter/main.dart';
import 'package:findany_flutter/profile/profile.dart';
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
  User? currentUser; // Store the current user

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
              currentAccountPicture: Align(
                alignment: Alignment.centerRight,
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
                  backgroundColor: Colors.white, // Add a background color if needed
                ),
              ),
              otherAccountsPictures: [
                // Add additional images if needed
              ],
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Profile()),
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
            GestureDetector(
              onTap: () {
                //utils.showToastMessage('Clicked', context);
              },
              child: Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Container(
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
      ),
    );
  }

  Future<void> loadData() async {
    loadingDialog.showDefaultLoading("Getting Details...");
    email = await utils.getCurrentUserEmail() ?? '';
    name = await sharedPreferences.getSecurePrefsValue("Name") ??  '';
    imageUrl = await sharedPreferences.getSecurePrefsValue('ProfileImageURL')?? '';

    EasyLoading.dismiss().then((value){
      setState(() {});
    });
  }

  Future<void> signOut() async {
    if (mounted) {
      loadingDialog.showDefaultLoading('Signing Out...');
      try {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().disconnect(); // Disconnect Google Sign-In

        EasyLoading.dismiss();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
        // Navigate to the login screen without checking mounted

      } catch (error) {
        print("Error signing out: $error");
        EasyLoading.dismiss();
      }
    }else{
      print('Unmounted singOut');
    }
  }

}
