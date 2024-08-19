import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/productdetails_provider.dart';
import '../services/FullScreenImageGallery.dart';
import 'merchantuploadpage.dart';

class ProductDetailPage extends StatefulWidget {
  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _currentIndex = 0;
  String _selectedColorId = '';
  bool _isOwner = false;

  Utils utils = Utils();
  FireStoreService fireStoreService = FireStoreService();
  LoadingDialog loadingDialog = LoadingDialog();
  late ProductDetailsProvider productDetailsProvider;
  var snapshot;

  @override
  void didChangeDependencies() {
    print("Product details page");
    super.didChangeDependencies();
    productDetailsProvider = Provider.of<ProductDetailsProvider>(context);
    snapshot = productDetailsProvider.getDetailsSnapshot();
    if (snapshot != null && snapshot.exists) {
      var productDetails = snapshot.data() as Map<String, dynamic>;

      List<String> colorIds = List<String>.from(productDetails['colors'] ?? []);
      if (colorIds.isNotEmpty) {
        _selectedColorId = colorIds[0];
      }

      _checkIfOwner(productDetails);
    }
  }

  Future<void> _checkIfOwner(Map<String, dynamic> productDetails) async {
    bool isOwner = await isUserOwner();
    if (mounted) {
      setState(() {
        _isOwner = isOwner;
      });
    }
  }

  Future<bool> isUserOwner() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference documentReference =
      FirebaseFirestore.instance.doc("/AdminDetails/DressShop");
      Map<String, dynamic>? data =
      await fireStoreService.getDocumentDetails(documentReference);
      Iterable ownerDetails = data!.values;
      return ownerDetails.contains(user.email);
    }
    return false;
  }

  void _openGallery(BuildContext context, List<String> media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageGallery(
          media: media,
          initialIndex: _currentIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var snapshot = productDetailsProvider.getDetailsSnapshot();
    if (snapshot == null || !snapshot.exists) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Product Details"),
        ),
        body: Center(
          child: Text("Product details not found."),
        ),
      );
    }

    var productDetails = snapshot.data() as Map<String, dynamic>;
    print("DressDetails: $productDetails");
    List<String> sizes = List<String>.from(productDetails['sizes'] ?? []);
    Map<String, List<String>> colorImages = (productDetails['media'] as Map<String, dynamic>).map((key, value) => MapEntry(key, List<String>.from(value as List<dynamic>)));

    // Get the media list for the selected color, or fallback to the first color or default media
    List<String> media = colorImages[_selectedColorId] ?? colorImages.values.first;

    // Calculate the discounted price
    double price = (productDetails['price'] as num?)?.toDouble() ?? 0.0;
    double discount = (productDetails['discount'] as num?)?.toDouble() ?? 0.0;
    double discountedPrice = price * (1 - discount / 100);

    // Convert the discounted price to an integer
    int discountedPriceInt = discountedPrice.toInt();

    return Scaffold(
      appBar: AppBar(
        title: Text(productDetails['name'] ?? "Product Details"),
        actions: [
          if (_isOwner)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MerchantUploadPage(),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                _openGallery(context, media);
              },
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 300.0,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  enableInfiniteScroll: true,
                  initialPage: 0,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
                items: media.map<Widget>((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                        ),
                        child: url.endsWith('.mp4')
                            ? Center(child: Text("Video Placeholder"))
                            : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/shop.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                productDetails['name'] ?? 'Product Name',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text(
                    '\₹$discountedPriceInt',
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  if (discount > 0)
                    Text(
                      '\₹${price.toInt()}',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                productDetails['description'] ?? 'No description available',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Available Sizes',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                spacing: 10.0,
                children: sizes.map((size) {
                  return ChoiceChip(
                    label: Text(size.toUpperCase()),
                    selected: false,
                    onSelected: (selected) {
                      // Handle size selection
                    },
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Available Colors',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                spacing: 10.0,
                children: colorImages.keys.map((colorId) {
                  Color color = Color(int.parse(colorId));
                  return ChoiceChip(
                    label: Container(
                      width: 24.0,
                      height: 24.0,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    selected: _selectedColorId == colorId,
                    onSelected: (selected) {
                      setState(() {
                        _selectedColorId = colorId;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    loadingDialog.showDefaultLoading("Adding to your cart");

                    // Get current user ID
                    String? uid = await utils.getCurrentUserUID();
                    if (uid == null) {
                      // Handle the case where the user is not authenticated
                      loadingDialog.dismiss();
                      return;
                    }
                    print("UID: $uid");

                    // Reference to the user's cart document
                    DocumentReference cartRef = FirebaseFirestore.instance.doc("/UserDetails/$uid/DressShop/Cart");

                    try {
                      // Add the new productID to the list without retrieving the current data
                      await cartRef.update({
                        "productIDs": FieldValue.arrayUnion([snapshot.reference])
                      });
                    } catch (e) {
                      print("Error adding product to cart: $e");
                    } finally {
                      loadingDialog.dismiss();
                    }
                  },

                  child: Text('Add to Cart'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    loadingDialog.dismiss();
    super.dispose();
  }

}