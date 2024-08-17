import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/storage.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;

import '../provider/productdetails_provider.dart';
import '../utils/utils.dart';

class MerchantUploadPage extends StatefulWidget {
  @override
  _MerchantUploadPageState createState() => _MerchantUploadPageState();
}

class _MerchantUploadPageState extends State<MerchantUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _uuid = Uuid();
  FireStoreService fireStoreService = FireStoreService();
  FirebaseStorageHelper firebaseStorageHelper = FirebaseStorageHelper();
  LoadingDialog loadingDialog = LoadingDialog();
  Utils utils = Utils();

  // Form fields
  String _name = '';
  String _description = '';
  double _price = 0.0;
  double _discount = 0.0;
  List<String> _sizes = [];
  List<Color> _colors = [];
  Map<Color, List<File>> _colorImages = {};

  String productId = "";

  // Dropdown fields
  String? _selectedCategory;
  String? _selectedSubCategory;

  final Map<String, List<String>> _categoryOptions = {
    'Men': [],
    'Women': [],
    'Kids': []
  };

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _sizesController = TextEditingController();

  late ProductDetailsProvider productDetailsProvider;

  DocumentSnapshot? snapshot;

  @override
  void initState() {
    super.initState();
    getSubcategory();
  }

  Future<void> getSubcategory() async {
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
        _categoryOptions[str] = allValues;
      }
    }
    setState(() {

    });
    print('subCategory: $_categoryOptions');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    productDetailsProvider = Provider.of<ProductDetailsProvider>(context);
    snapshot = context.read<ProductDetailsProvider>().getDetailsSnapshot();
    if(snapshot !=null){
      _initializeProductDetails();
    }

  }

  Future<void> _initializeProductDetails() async {
    loadingDialog.showDefaultLoading("Getting Product Details...");

    if (snapshot != null && snapshot!.exists) {
      var productDetails = snapshot!.data() as Map<String, dynamic>;
      print("Product Details: $productDetails");
      setState(() {
        _name = productDetails['name'] ?? 'N/A';
        _description = productDetails['description'] ?? 'N/A';
        _price = (productDetails['price'] ?? 0).toDouble();
        _discount = (productDetails['discount'] ?? 0).toDouble();
        _sizes = List<String>.from(productDetails['sizes'] ?? []);
        _colors = (productDetails['colors'] ?? [])
            .map<Color>((colorValue) => Color(int.parse(colorValue)))
            .toList();
        _selectedCategory = productDetails['category'];
        _selectedSubCategory = productDetails['subCategory'];
        productId = productDetails['productId'] ?? _uuid.v4();
      });

      _colorImages = {};
      Map<String, dynamic> mediaUrls = productDetails['media'] ?? {};

      for (var entry in mediaUrls.entries) {
        String color = entry.key;
        List<dynamic> urlList = entry.value;

        Color parsedColor = Color(int.parse(color));
        List<File> files = await downloadImages(List<String>.from(urlList));
        print("Files: $files");
        if (mounted) {
          setState(() {
            _colorImages[parsedColor] = files;
          });
        }
      }
      print("Product ID: $productId");
      print("Downloaded Images: $_colorImages");
      _nameController.text = _name;
      _descriptionController.text = _description;
      _priceController.text = _price.toString();
      _discountController.text = _discount.toString();
      _sizesController.text = _sizes.join(', ');
    } else {
      productId = _uuid.v4();
    }
    loadingDialog.dismiss();
  }

  Future<List<File>> downloadImages(List<dynamic> urls) async {
    List<File> files = [];

    for (String url in urls) {
      print("Url: $url");
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final directory = await getTemporaryDirectory();
          final fileName = Uri.parse(url).pathSegments.last;
          final filePath = '${directory.path}/$fileName';

          // Create the parent directory if it doesn't exist
          final fileDirectory = Directory(filePath).parent;
          if (!await fileDirectory.exists()) {
            await fileDirectory.create(recursive: true);
            print('Directory created: ${fileDirectory.path}');
          } else {
            print('Directory already exists: ${fileDirectory.path}');
          }

          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          if (await file.exists()) {
            files.add(file);
            print('File downloaded: $filePath');
          } else {
            print('File not found after writing: $filePath');
          }
        } else {
          print('Failed to download image, status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error downloading image from URL $url: $e');
      }
    }
    return files;
  }

  Future<void> _pickColorAndImages() async {
    Color? pickedColor = await _pickColor(context);
    if (pickedColor != null && !_colors.contains(pickedColor)) {
      List<File> pickedImages = await _pickImagesForColor(pickedColor);
      setState(() {
        _colors.add(pickedColor);
        _colorImages[pickedColor] = pickedImages;
      });
    }
  }

  Future<Color?> _pickColor(BuildContext context) async {
    Color pickedColor = Colors.blue;
    return await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickedColor,
              onColorChanged: (Color color) {
                pickedColor = color;
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(pickedColor);
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<File>> _pickImagesForColor(Color color) async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      return pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
    }
    return [];
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      loadingDialog.showDefaultLoading("Uploading Data");

      try {
        firebaseStorageHelper.deleteFolder("/DressShopImages/$productId");

        final Map<String, dynamic> media = {};
        for (var entry in _colorImages.entries) {
          String color = entry.key.value.toString();
          List<File> images = entry.value;
          List<String> imageUrls = [];
          for(File file in images){
            String downloadUrl =await firebaseStorageHelper.uploadFile(file, 'DressShopImages/$productId/$color/', file.path.split('/').last);
            imageUrls.add(downloadUrl);
          }
          if (imageUrls.isNotEmpty) {
            media[color] = imageUrls;
          }
        }
        print("Media: $media");

        Map<String, dynamic> data = {
          'name': _name,
          'description': _description,
          'price': _price,
          'discount': _discount,
          'sizes': _sizes,
          'colors': media.keys,
          'media': media,
          'productId': productId,
          'category': _selectedCategory,
          'subCategory': _selectedSubCategory,
        };
        print("Data: $data");
        print("ProductID: $productId");
        DocumentReference documentReference = FirebaseFirestore.instance.doc('/SHOPS/DRESSSHOP/$_selectedCategory/$productId');
        await fireStoreService.setMapDataToFirestore(data, documentReference);

        DocumentSnapshot documentSnapshot = await documentReference.get();
        print("Document Snapshot: ${documentSnapshot.data()}");

        productDetailsProvider.updateDetailsSnapshot(documentSnapshot);

        utils.clearCache();
        Navigator.pop(context);

        loadingDialog.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product uploaded successfully')),
        );
      } catch (e) {
        loadingDialog.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Product'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Product Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a product name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _name = value!;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _description = value!;
                  },
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) {
                    _price = double.tryParse(value!) ?? 0.0;
                  },
                ),
                TextFormField(
                  controller: _discountController,
                  decoration: InputDecoration(labelText: 'Discount'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) {
                    _discount = double.tryParse(value!) ?? 0.0;
                  },
                ),
                TextFormField(
                  controller: _sizesController,
                  decoration: InputDecoration(labelText: 'Sizes (comma-separated)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter sizes';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _sizes = value!.split(',').map((size) => size.trim()).toList();
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(labelText: 'Category'),
                  items: _categoryOptions.keys
                      .map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _selectedSubCategory = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                if (_selectedCategory != null)
                  DropdownButtonFormField<String>(
                    value: _selectedSubCategory,
                    decoration: InputDecoration(labelText: 'Subcategory'),
                    items: _categoryOptions[_selectedCategory]!
                        .map((subcategory) => DropdownMenuItem(
                      value: subcategory,
                      child: Text(subcategory),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a subcategory';
                      }
                      return null;
                    },
                  ),
                SizedBox(height: 16.0),
                Text('Select Colors and Upload Images:'),
                SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  children: _colors.map((color) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            List<File> images = await _pickImagesForColor(color);
                            setState(() {
                              _colorImages[color] = images;
                            });
                          },
                          child: Chip(
                            backgroundColor: color,
                            label: Text(
                              _colorImages[color] != null
                                  ? '${_colorImages[color]!.length} images'
                                  : 'No images',
                              style: TextStyle(
                                  color: useWhiteForeground(color) ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.0),
                        if (_colorImages[color] != null && _colorImages[color]!.isNotEmpty)
                          Wrap(
                            spacing: 8.0,
                            children: _colorImages[color]!.asMap().entries.map((entry) {
                              int index = entry.key;
                              File imageFile = entry.value;
                              return Stack(
                                children: [
                                  Image.file(
                                    imageFile,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    right: 0,
                                    child: IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _colorImages[color]?.removeAt(index);
                                          if (_colorImages[color]?.isEmpty ?? false) {
                                            _colors.remove(color);
                                            _colorImages.remove(color);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                      ],
                    );
                  }).toList(),
                ),
                ElevatedButton(
                  onPressed: _pickColorAndImages,
                  child: Text('Add Color and Images'),
                ),
                SizedBox(height: 16.0),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('Upload Product'),
                  ),
                ),
              ],
            ),
          ),
        ),
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
