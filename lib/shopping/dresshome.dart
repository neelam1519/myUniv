import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/shopping/cartpage.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../provider/productdetails_provider.dart';
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
  String? selectedSubcategory;
  List<DocumentSnapshot> products = [];
  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMoreProducts = true;
  String _searchQuery = "";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  late ProductDetailsProvider productDetailsProvider;
  LoadingDialog loadingDialog = LoadingDialog();

  Map<String, List<String>> subcategories = {
    'Men': [],
    'Women': [],
    'Kids': [],
  };

  @override
  void initState() {
    super.initState();
    getSubcategory();
    _checkIfOwner();
    _fetchInitialProducts();
  }
  Future<void> getSubcategory() async {
    loadingDialog.showDefaultLoading("Getting Details");
    CollectionReference collectionReference = FirebaseFirestore.instance.collection("SHOPS/DRESSSHOP/Category");
    List<String> documents = await fireStoreService.getDocumentNames(collectionReference);

    for (String str in documents) {
      DocumentReference documentReference = FirebaseFirestore.instance.doc("SHOPS/DRESSSHOP/Category/$str");
      Map<String, dynamic>? data = await fireStoreService.getDocumentDetails(documentReference);

      if (data != null && data.isNotEmpty) {
        List<String> allValues = [];
        for (var value in data.values) {
            allValues.add(value);
        }
        // Update the subcategories map
        subcategories[str] = allValues;
      }
    }
    setState(() {

    });
    print('subCategory: $subcategories');
  }


  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    productDetailsProvider = Provider.of<ProductDetailsProvider>(context);

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
      DocumentReference documentReference =
      FirebaseFirestore.instance.doc("/AdminDetails/DressShop");
      Map<String, dynamic>? data =
      await fireStoreService.getDocumentDetails(documentReference);
      Iterable ownerDetails = data!.values;
      return ownerDetails.contains(user.email);
    }
    return false;
  }

  Future<void> _fetchInitialProducts() async {
    setState(() {
      isLoading = true;
    });

    Query query = _buildQuery();

    QuerySnapshot querySnapshot = await query.limit(4).get();
    setState(() {
      products = querySnapshot.docs;
      if (products.isNotEmpty) {
        lastDocument = products.last;
      }
      isLoading = false;
      hasMoreProducts = querySnapshot.docs.length == 4;
    });
    loadingDialog.dismiss();
  }

  Future<void> _fetchMoreProducts() async {
    if (isLoadingMore || !hasMoreProducts) return;

    setState(() {
      isLoadingMore = true;
    });

    Query query = _buildQuery().startAfterDocument(lastDocument!);

    QuerySnapshot querySnapshot = await query.limit(4).get();
    setState(() {
      products.addAll(querySnapshot.docs);
      if (querySnapshot.docs.isNotEmpty) {
        lastDocument = querySnapshot.docs.last;
      }
      isLoadingMore = false;
      hasMoreProducts = querySnapshot.docs.length == 4;
    });
  }

  Query _buildQuery() {
    CollectionReference collectionRef = FirebaseFirestore.instance
        .collection('/SHOPS/DRESSSHOP/$category');

    Query query = collectionRef;

    // Apply subcategory filter if selected
    if (selectedSubcategory != null) {
      query = query.where('subCategory', isEqualTo: selectedSubcategory);
    }

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThan: _searchQuery + 'z');
    }

    return query;
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
          content: Text(
              "Are you sure you want to delete this product permanently?"),
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
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
              _fetchInitialProducts(); // Update the products when search query changes
            });
          },
          decoration: InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
        )
            : Text('FindAny'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = "";
                  _fetchInitialProducts(); // Reset the products
                });
              },
            )
          else if (_isOwner)
            IconButton(
              icon: Icon(Icons.upload_file),
              onPressed: _navigateToUploadPage,
            ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
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
          if (subcategories.containsKey(category))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                height: 50.0,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: subcategories[category]!.map((subcategory) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSubcategory = subcategory;
                          _fetchInitialProducts(); // Update the products when subcategory changes
                        });
                      },
                      child: Container(
                        width: 100.0,
                        margin: EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          color: selectedSubcategory == subcategory
                              ? Colors.orange
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: Text(
                            subcategory,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? _buildShimmerLoader()
                : products.isEmpty
                ? Center(child: Text('No dresses available'))
                : NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollEndNotification &&
                    scrollNotification.metrics.pixels ==
                        scrollNotification.metrics.maxScrollExtent) {
                  _fetchMoreProducts();
                }
                return false;
              },
              child: GridView.builder(
                padding: EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 2 / 3,
                ),
                itemCount: products.length + 1,
                itemBuilder: (context, index) {
                  if (index == products.length) {
                    return isLoadingMore
                        ? Center(child: CircularProgressIndicator())
                        : SizedBox(); // Empty space at the bottom if not loading more
                  }
                  DocumentSnapshot doc = products[index];
                  return _buildProductItem(doc);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return GridView.builder(
      padding: EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 2 / 3,
      ),
      itemCount: 4, // Number of shimmer placeholders to display
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: Colors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  color: Colors.white,
                  height: 16.0,
                  width: 80.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  color: Colors.white,
                  height: 16.0,
                  width: 40.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(String categoryName) {
    bool isSelected = categoryName == category;

    // Map of category images
    Map<String, String> categoryImages = {
      'Men': 'assets/images/mendress.png',
      'Women': 'assets/images/womendress.png',
      'Kids': 'assets/images/kidsdress.png',
    };

    return GestureDetector(
      onTap: () {
        setState(() {
          category = categoryName;
          selectedSubcategory = null;
          _fetchInitialProducts(); // Update the products when category changes
        });
      },
      child: Container(
        width: 100.0,
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the category image and fit it to the screen
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0), // Match the container's border radius
              child: Image.asset(
                categoryImages[categoryName]!,
                fit: BoxFit.contain, // Ensures the whole image is visible within the container
                width: 60.0, // Specify width to ensure uniformity
                height: 60.0, // Specify height to ensure uniformity
              ),
            ),
            SizedBox(height: 8.0),
            // Display the category name
            Text(
              categoryName,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    String name = data['name'] ?? 'No Name';
    String price = data['price']?.toString() ?? 'No Price';

    // Extract the color IDs from the 'colors' array
    List<String> colorIds = List<String>.from(data['colors'] ?? []);

    // Select the first color ID
    String? firstColorId = colorIds.isNotEmpty ? colorIds[0] : null;

    // Get the media map
    Map<String, dynamic> mediaMap = data['media'] ?? {};


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
        productDetailsProvider.updateDetailsSnapshot(document);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(),
          ),
        );
      },
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: mediaUrl ?? '',
                placeholder: (context, url) =>
                    Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    Center(child: Icon(Icons.error)),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Rs. $price'),
            ),
            if (_isOwner)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteProduct(document.reference),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToUploadPage() {
    productDetailsProvider.updateDetailsSnapshot(null);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MerchantUploadPage(),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    loadingDialog.dismiss();
  }

}
