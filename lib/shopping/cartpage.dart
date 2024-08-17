import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/productdetails_provider.dart';
import 'productdetailspage.dart';

class CartDetailsPage extends StatefulWidget {
  @override
  _CartDetailsPageState createState() => _CartDetailsPageState();
}

class _CartDetailsPageState extends State<CartDetailsPage> {
  List<DocumentSnapshot> products = [];
  bool isLoading = true;
  Utils utils = Utils();

  late ProductDetailsProvider productDetailsProvider;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    productDetailsProvider = Provider.of<ProductDetailsProvider>(context);

  }

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    String? uid = await utils.getCurrentUserUID();
    DocumentReference cartRef = FirebaseFirestore.instance.doc("/UserDetails/$uid/DressShop/Cart");

    DocumentSnapshot cartSnapshot = await cartRef.get();
    List<dynamic> productRefs = cartSnapshot['productIDs'];
    List<DocumentSnapshot> fetchedProducts = [];

    for (DocumentReference productRef in productRefs) {
      DocumentSnapshot productSnapshot = await productRef.get();
      fetchedProducts.add(productSnapshot);
    }

    setState(() {
      products = fetchedProducts;
      isLoading = false;
    });
  }

  Future<void> _removeFromCart(DocumentReference productRef) async {
    String? uid = await utils.getCurrentUserUID();
    DocumentReference cartRef = FirebaseFirestore.instance.doc("/UserDetails/$uid/DressShop/Cart");

    DocumentSnapshot cartSnapshot = await cartRef.get();
    List<dynamic> productRefs = cartSnapshot['productIDs'];

    productRefs.remove(productRef);

    await cartRef.update({
      'productIDs': productRefs,
    });

    setState(() {
      products.removeWhere((doc) => doc.reference == productRef);
    });
  }

  void _confirmRemoveFromCart(DocumentReference productRef) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Remove Item"),
          content: Text("Are you sure you want to remove this item from your cart?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Remove"),
              onPressed: () {
                Navigator.of(context).pop();
                _removeFromCart(productRef);
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

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? Center(child: Text("Your cart is empty"))
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          var product = products[index].data() as Map<String, dynamic>;

          // Calculate discounted price
          double price = product['price'] ?? 0.0;
          double discount = product['discount'] ?? 0.0;
          double discountedPrice = price * (1 - discount / 100);

          // Extract the color IDs from the 'colors' array
          List<String> colorIds = List<String>.from(product['colors'] ?? []);

          // Select the first color ID
          String? firstColorId = colorIds.isNotEmpty ? colorIds[0] : null;

          // Get the media map
          Map<String, dynamic> mediaMap = product['media'] ?? {};


          // Get the first image URL of the first color, or fallback to the first image in media
          String? mediaUrl = firstColorId != null && mediaMap.containsKey(firstColorId)
              ? (mediaMap[firstColorId] as List<dynamic>?)?.isNotEmpty == true
              ? mediaMap[firstColorId][0]
              : null
              : mediaMap.values.isNotEmpty
              ? (mediaMap.values.first as List<dynamic>?)?.isNotEmpty == true
              ? mediaMap.values.first[0]
              : null
              : null;

          return GestureDetector(
            onTap: () {
              productDetailsProvider.updateDetailsSnapshot(products[index]);
              // Define the action when the card is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(),
                ),
              );
            },
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Image.network(
                      mediaUrl!,
                      width: 80.0,
                      height: 80.0,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            "\₹${discountedPrice.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _confirmRemoveFromCart(products[index].reference);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}
