import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  ProductDetailPage({required this.productId});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Map<String, dynamic>> _productDetails;
  bool _isLoading = true;

  // Default data
  final Map<String, dynamic> _defaultProductData = {
    'name': 'Loading Product...',
    'cost': 0.0,
    'rating': 0.0,
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': [Colors.grey, Colors.grey, Colors.grey],
    'media': [
      'https://via.placeholder.com/400x300?text=Loading+Image+1',
      'https://via.placeholder.com/400x300?text=Loading+Image+2',
      'https://via.placeholder.com/400x300?text=Loading+Image+3'
    ],
  };

  @override
  void initState() {
    super.initState();
    _productDetails = _fetchProductDetails();
  }

  Future<Map<String, dynamic>> _fetchProductDetails() async {
    try {
      // Fetch product details from Firestore
      DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (!productSnapshot.exists) {
        throw Exception("Product not found");
      }

      Map<String, dynamic> productData = productSnapshot.data() as Map<String, dynamic>;

      // Fetch image/video URLs from Firebase Storage
      List<String> imageUrls = await _fetchMediaUrls(productData['media']);

      setState(() {
        _isLoading = false;
      });

      return {
        'name': productData['name'],
        'cost': productData['cost'],
        'rating': productData['rating'],
        'sizes': List<String>.from(productData['sizes']),
        'colors': (productData['colors'] as List)
            .map((color) => Color(int.parse(color)))
            .toList(),
        'media': imageUrls,
      };
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      return _defaultProductData; // Return default data in case of an error
    }
  }

  Future<List<String>> _fetchMediaUrls(List<dynamic> mediaRefs) async {
    List<String> urls = [];
    for (var ref in mediaRefs) {
      String url = await FirebaseStorage.instance.ref(ref).getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Product Details"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _productDetails,
        builder: (context, snapshot) {
          // Use default data if loading
          var product = _isLoading ? _defaultProductData : snapshot.data ?? _defaultProductData;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image/Video Carousel
                CarouselSlider(
                  options: CarouselOptions(
                    height: 300.0,
                    enlargeCenterPage: true,
                    autoPlay: true,
                    aspectRatio: 16 / 9,
                    enableInfiniteScroll: true,
                    initialPage: 0,
                  ),
                  items: product['media'].map<Widget>((url) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                          ),
                          child: url.endsWith('.mp4')
                              ? Center(child: Text("Video Placeholder"))
                              : Image.network(
                            url,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    product['name'],
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
                        '\$${product['cost']}',
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.yellow, size: 18),
                          SizedBox(width: 5),
                          Text(
                            '${product['rating']}',
                            style: TextStyle(
                              fontSize: 18.0,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    children: (product['sizes'] as List<String>).map((size) {
                      return ChoiceChip(
                        label: Text(size),
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
                    children: (product['colors'] as List<Color>).map((color) {
                      return ChoiceChip(
                        label: Container(
                          width: 24.0,
                          height: 24.0,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        selected: false,
                        onSelected: (selected) {
                          // Handle color selection
                        },
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20.0),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle add to cart
                    },
                    child: Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 15.0),
                      textStyle: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
              ],
            ),
          );
        },
      ),
    );
  }
}
