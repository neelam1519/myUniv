import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late Stream<QuerySnapshot> _dressStream;

  @override
  void initState() {
    super.initState();
    _checkIfOwner();
    _dressStream = _getDressStream();
  }

  void _checkIfOwner() async {
    bool isOwner = await isUserOwner();
    setState(() {
      _isOwner = isOwner;
    });
  }

  Future<bool> isUserOwner() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference documentReference = FirebaseFirestore.instance.doc("/AdminDetails/DressShop");
      Map<String, dynamic>? data = await fireStoreService.getDocumentDetails(documentReference);
      Iterable ownerDetails = data!.values;
      return ownerDetails.contains(user.email);
    }
    return false;
  }

  Stream<QuerySnapshot> _getDressStream() {
    return FirebaseFirestore.instance
        .collection('/SHOPS/DRESSSHOP/$category')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('FindAny'),
        actions: [
          if (_isOwner)
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dressStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No products available'));
                }
                return GridView.builder(
                  padding: EdgeInsets.all(8.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 2 / 3,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    return _buildProductItem(doc);
                  },
                );
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
    return GestureDetector(
      onTap: () {
        setState(() {
          category = title;
          _dressStream = _getDressStream(); // Update the stream when category changes
        });
      },
      child: Container(
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
      ),
    );
  }

  Widget _buildProductItem(DocumentSnapshot doc) {
    String imageUrl = (doc['media'] as List).isNotEmpty ? doc['media'][0] : 'https://via.placeholder.com/150';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(productId: doc['productId']),
          ),
        );
      },
      child: Card(
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset('assets/images/shop.png', fit: BoxFit.cover);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                doc['name'] ?? 'Product Name',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '\$${doc['price'] ?? 0}',
              style: TextStyle(color: Colors.green, fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }
}
