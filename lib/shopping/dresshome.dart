  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:findany_flutter/Firebase/firestore.dart';
  import 'package:findany_flutter/Firebase/realtimedatabase.dart';
  import 'package:findany_flutter/provider/dress_provider.dart';
  import 'package:findany_flutter/shopping/cartpage.dart';
  import 'package:findany_flutter/shopping/merchantuploadpage.dart';
  import 'package:findany_flutter/shopping/productdetailspage.dart';
  import 'package:findany_flutter/utils/LoadingDialog.dart';
  import 'package:flutter/material.dart';
  import 'package:cached_network_image/cached_network_image.dart';
  import 'package:flutter_linkify/flutter_linkify.dart';
  import 'package:provider/provider.dart';
  import 'package:shimmer/shimmer.dart';
  import 'package:url_launcher/url_launcher.dart';
  import '../provider/productdetails_provider.dart';
  import 'package:firebase_database/firebase_database.dart' as database;

  class DressHome extends StatefulWidget {
    @override
    _DressHomeState createState() => _DressHomeState();
  }

  class _DressHomeState extends State<DressHome> {
    int _selectedIndex = 0;
    bool _isOwner = false;
    FireStoreService fireStoreService = FireStoreService();
    RealTimeDatabase realTimeDatabase = RealTimeDatabase();
    String category = "Men";
    String? selectedSubcategory;
    DocumentSnapshot? lastDocument;
    bool isLoading = false;
    bool isLoadingMore = false;
    bool hasMoreProducts = true;
    String _searchQuery = "";
    bool _isSearching = false;
    final TextEditingController _searchController = TextEditingController();

    late ProductDetailsProvider productDetailsProvider;
    late DressProvider dressProvider;

    LoadingDialog loadingDialog = LoadingDialog();

    String announcementText = "";

    @override
    void initState() {
      super.initState();
      fetchAnnouncementText();
      _fetchInitialProducts();
    }

    Future<void> fetchAnnouncementText() async {
      announcementText = await realTimeDatabase.getCurrentValue("SHOPS/DressShopAnnouncement");
      print("Announcement Text: $announcementText");
      listenForAnnouncementTextChanges();
      setState(() {});
    }

    void listenForAnnouncementTextChanges() {
      database.DatabaseReference announcementRef =
      database.FirebaseDatabase.instance.ref("SHOPS/DressShopAnnouncement");

      announcementRef.onValue.listen((event) {
        final newText = event.snapshot.value as String?;
        if (newText != null) {
          setState(() {
            announcementText = newText;
            print("Updated Announcement Text: $announcementText");
          });
        }
      });
    }

    @override
    void didChangeDependencies() {
      print('didChangeDependencies');
      super.didChangeDependencies();
      productDetailsProvider = Provider.of<ProductDetailsProvider>(context);
      dressProvider = Provider.of<DressProvider>(context);
    }

    Future<void> _fetchInitialProducts() async {
      setState(() {
        isLoading = true;
      });

      Query query = _buildQuery();

      QuerySnapshot querySnapshot = await query.limit(4).get();
      setState(() {
        productDetailsProvider.updateProductSnapshots(querySnapshot.docs);
        if (querySnapshot.docs.isNotEmpty) {
          lastDocument = querySnapshot.docs.last;
        }
        isLoading = false;
        hasMoreProducts = querySnapshot.docs.length == 4;
      });
    }

    Future<void> _fetchMoreProducts() async {
      if (isLoadingMore || !hasMoreProducts) return;

      setState(() {
        isLoadingMore = true;
      });

      Query query = _buildQuery().startAfterDocument(lastDocument!);

      QuerySnapshot querySnapshot = await query.limit(4).get();
      setState(() {
        productDetailsProvider.updateProductSnapshots([
          ...productDetailsProvider.getProductsSnapshots(),
          ...querySnapshot.docs,
        ]);
        if (querySnapshot.docs.isNotEmpty) {
          lastDocument = querySnapshot.docs.last;
        }
        isLoadingMore = false;
        hasMoreProducts = querySnapshot.docs.length == 4;
      });
    }


    Query _buildQuery() {
      CollectionReference collectionRef =
      FirebaseFirestore.instance.collection('/SHOPS/DRESSSHOP/$category');

      Query query = collectionRef;

      if (selectedSubcategory != null) {
        query = query.where('subCategory', isEqualTo: selectedSubcategory);
      }

      if (_searchQuery.isNotEmpty) {
        query = query
            .where('name', isGreaterThanOrEqualTo: _searchQuery)
            .where('name', isLessThan: _searchQuery + 'z');
      }
      return query;
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
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    // Delete the product from Firestore
                    await productRef.delete();

                    productDetailsProvider.removeProductByReference(productRef);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Product deleted successfully")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to delete product")),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    }

    @override
    Widget build(BuildContext context) {
      print("DressHome Page");
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber,
          title: _isSearching
              ? TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (query) {
              setState(() {
                _searchQuery = query;
                _fetchInitialProducts();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search...',
              border: InputBorder.none,
            ),
          )
              : Text('FindAny'),
          actions: _selectedIndex == 0
              ? [
            if (_isSearching)
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _searchQuery = "";
                    _fetchInitialProducts();
                  });
                },
              )
            else
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
          ]
              : null,
        ),
        body: Column(
          children: [
            if (announcementText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
                child: Linkify(
                  text: announcementText,
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  linkStyle: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  onOpen: (link) async {
                    if (await canLaunch(link.url)) {
                      await launch(link.url);
                    } else {
                      throw 'Could not launch ${link.url}';
                    }
                  },
                ),
              ),
            Expanded(
              child: _buildPage(_selectedIndex), // Main content goes here
            ),
          ],
        ),
        bottomNavigationBar: buildBottomNavigationBar(),
      );
    }


    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
        if(index == 2){
          productDetailsProvider.updateDetailsSnapshot(null);
        }
      });
    }

    Widget _buildPage(int index) {
      switch (index) {
        case 0:
          return buildHomePage();
        case 1:
          return CartDetailsPage();
        case 2:
          return MerchantUploadPage();
        case 3:
          return MerchantUploadPage(); // Replace with your ProfilePage widget
        default:
          return CartDetailsPage();
      }
    }

    Widget buildBottomNavigationBar() {
      return BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      );
    }

    Widget buildHomePage() {
      print("Building home page");
      return Column(
        children: [
          buildCategories(),
          buildProductList(),
        ],
      );
    }

    Widget buildCategories() {
      dressProvider.getCategories();
      List<String> categoryList = dressProvider.categories.toSet().toList(); // Ensure uniqueness
      Map<String, List<String>> subcategories = dressProvider.subCategories;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Align the entire column to the start (left)
        children: [
          SizedBox(height: 10.0),

          // Category Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align the row to the start
              children: categoryList.map((categoryName) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      category = categoryName;
                      selectedSubcategory = null;
                      _fetchInitialProducts();
                    });
                  },
                  child: Container(
                    alignment: Alignment.centerLeft, // Align text to the left
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    margin: EdgeInsets.only(right: 8.0), // Align margin to the right to keep left aligned
                    decoration: BoxDecoration(
                      gradient: category == categoryName
                          ? LinearGradient(
                        colors: [Colors.blueAccent, Colors.lightBlueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : LinearGradient(
                        colors: [Colors.grey[300]!, Colors.grey[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        if (category == categoryName)
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.4),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                      ],
                    ),
                    child: Text(
                      categoryName,
                      textAlign: TextAlign.left, // Ensure text alignment is to the left
                      style: TextStyle(
                        fontSize: 16.0,
                        color: category == categoryName ? Colors.white : Colors.black87,
                        fontWeight: category == categoryName
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Subcategory Row
          if (subcategories[category]!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align the row to the start
                  children: subcategories[category]!.map((subcategoryName) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSubcategory = subcategoryName;
                          _fetchInitialProducts();
                        });
                      },
                      child: Container(
                        alignment: Alignment.centerLeft, // Align text to the left
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        margin: EdgeInsets.only(right: 8.0), // Align margin to the right to keep left aligned
                        decoration: BoxDecoration(
                          gradient: selectedSubcategory == subcategoryName
                              ? LinearGradient(
                            colors: [Colors.blueAccent, Colors.lightBlueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : LinearGradient(
                            colors: [Colors.grey[300]!, Colors.grey[400]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            if (selectedSubcategory == subcategoryName)
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.4),
                                spreadRadius: 3,
                                blurRadius: 5,
                              ),
                          ],
                        ),
                        child: Text(
                          subcategoryName,
                          textAlign: TextAlign.left, // Ensure text alignment is to the left
                          style: TextStyle(
                            fontSize: 14.0,
                            color: selectedSubcategory == subcategoryName
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: selectedSubcategory == subcategoryName
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      );
    }

    Widget buildProductList() {
      List<DocumentSnapshot> products = productDetailsProvider.getProductsSnapshots();

      return Expanded(
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && !isLoadingMore) {
              _fetchMoreProducts();
            }
            return false;
          },
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : products.isEmpty
              ? Center(child: Text("No products found"))
              : ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              DocumentSnapshot product = products[index];

              String name = product['name'];
              String description = product['description'];
              double fullPrice = product['price'];
              double discount = product['discount'];
              double price = fullPrice * (1 - discount / 100);
              int finalPrice = price.round();

              Map<String, dynamic> mediaMap = product['media'];
              List<String> colors = List<String>.from(product['colors']);
              String firstColor = colors.first;
              List<dynamic> imagesForFirstColor = mediaMap[firstColor] ?? [];

              String imageUrl = imagesForFirstColor.isNotEmpty ? imagesForFirstColor.first : '';

              dressProvider.isUserOwner();
              _isOwner = dressProvider.isOwner;

              return GestureDetector(
                onTap: () {
                  productDetailsProvider.updateDetailsSnapshot(product);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.all(10.0),
                  elevation: 5.0,
                  child: Row(
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 100.0,
                            height: 100.0,
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        width: 100.0,
                        height: 100.0,
                        fit: BoxFit.cover,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                    fontSize: 16.0, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 5.0),
                              Text(
                                description,
                                style: TextStyle(fontSize: 14.0),
                              ),
                              SizedBox(height: 5.0),
                              Text(
                                '₹${finalPrice}',
                                style: TextStyle(fontSize: 16.0, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isOwner)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _confirmDeleteProduct(product.reference);
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    @override
    void dispose() {
      super.dispose();
    }

  }
