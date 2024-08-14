import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../services/FullScreenImageGallery.dart';

class ProductDetailPage extends StatefulWidget {
  final DocumentSnapshot documentSnapshot;

  ProductDetailPage({required this.documentSnapshot});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    var product = widget.documentSnapshot.data() as Map<String, dynamic>;

    List<String> sizes = (product['sizes'] as List<dynamic>).cast<String>();
    List<String> media = (product['media'] as List<dynamic>).cast<String>();
    List<Color> colors = (product['colors'] as List<dynamic>)
        .map((color) => Color(int.parse(color)))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? "Product Details"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel with zoom and swipe functionality
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
                          errorWidget: (context, url, error) =>
                              Image.asset(
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
                product['name'] ?? 'Product Name',
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
                    '\$${product['price'] ?? 0.0}',
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
                        '${product['rating'] ?? 0.0}',
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
                children: colors.map((color) {
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
      ),
    );
  }

  void _openGallery(BuildContext context, List<String> media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageGallery(media: media, initialIndex: _currentIndex),
      ),
    );
  }
}