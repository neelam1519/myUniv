import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dressdetailspage.dart';
import 'dressuploadpage.dart';

class DressHome extends StatefulWidget {
  @override
  _DressHomeState createState() => _DressHomeState();
}

class _DressHomeState extends State<DressHome> {

  bool _isOwner = false;
  FireStoreService fireStoreService = FireStoreService();
  String category = "Men";

  @override
  void initState() {
    super.initState();
    _checkIfOwner();
  }

  void _checkIfOwner() async {
    bool isOwner = await isUserOwner();
    setState(() {
      _isOwner = isOwner;
    });
  }

  Future<void> getProducts() async{
  CollectionReference collectionReference = FirebaseFirestore.instance.collection("/SHOPS/DRESSSHOP/Men");
  }

  Future<bool> isUserOwner() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {

      DocumentReference documentReference= FirebaseFirestore.instance.doc("/AdminDetails/DressShop");
      Map<String,dynamic>? data = await fireStoreService.getDocumentDetails(documentReference);

      Iterable ownerDetails = data!.values;
      print('Dress Owner Details: $ownerDetails');

      if(ownerDetails.contains(user.email)){
        return true;
      }else{
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('FindAny'),
        actions: [
          if (_isOwner) // Only show upload button if the user is the owner
            IconButton(
              icon: Icon(Icons.upload_file),
              onPressed: _navigateToUploadPage,
            ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search for products, brands and more',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          // Category Section
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Container(
              height: 100.0,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryItem('Men'),
                  _buildCategoryItem('Women'),
                  _buildCategoryItem('Kids'),
                ],
              ),
            ),
          ),
          // Product Grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 2 / 3,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                return _buildProductItem();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToUploadPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MerchantUploadPage(),
      ),
    );
  }

  Widget _buildCategoryItem(String title) {
    return Container(
      width: 80.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30.0,
            backgroundColor: Colors.blue,
            child: Icon(Icons.category, color: Colors.white),
          ),
          SizedBox(height: 8.0),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildProductItem() {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: Image.network(
              'https://via.placeholder.com/150',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Product Name',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '\$50',
            style: TextStyle(color: Colors.green, fontSize: 16.0),
          ),
          SizedBox(height: 8.0),
        ],
      ),
    );
  }
}
