import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/shopping/cartpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  Future<void> _deleteProduct(DocumentReference productRef) async {
    try {
      await productRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Product deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete product")),
      );
    }
  }

  void _confirmDeleteProduct(DocumentReference productRef) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Product"),
          content: Text("Are you sure you want to delete this product permanently?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(productRef);
              },
            ),
          ],
        );
      },
    );
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartDetailsPage(),
                ),
              );
            },
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
            builder: (context) => ProductDetailPage(documentSnapshot: doc),
          ),
        );
      },
      child: Card(
        child: Stack(
          children: [
            // Product Image
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => Image.asset('assets/images/shop.png', fit: BoxFit.cover),
              height: 200.0, // Adjust the height as needed
              width: double.infinity, // Fill the width of the container
            ),
            // Delete Button
            if (_isOwner)
              Positioned(
                top: 8.0,
                right: 8.0,
                child: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 24.0),
                  onPressed: () {
                    _confirmDeleteProduct(doc.reference);
                  },
                ),
              ),
            // Product Details
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8.0),
                color: Colors.white.withOpacity(0.7), // Background color with transparency
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc['name'] ?? 'Product Name',
                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\₹${(doc['price'] ?? 0).toInt()}',
                      style: TextStyle(color: Colors.green, fontSize: 16.0),
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

}
