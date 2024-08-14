import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/storage.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class MerchantUploadPage extends StatefulWidget {
  @override
  _MerchantUploadPageState createState() => _MerchantUploadPageState();
}

class _MerchantUploadPageState extends State<MerchantUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _uuid = Uuid();
  FireStoreService fireStoreService = FireStoreService();
  FirebaseStorageHelper firebaseStorageHelper= FirebaseStorageHelper();

  LoadingDialog loadingDialog = LoadingDialog();

  // Form fields
  String _name = '';
  String _description = '';
  double _price = 0.0;
  double _discount = 0.0;
  List<String> _sizes = [];
  List<Color> _colors = [];
  List<File> _images = [];

  String productId = "";

  // Dropdown fields
  String? _selectedCategory;
  String? _selectedSubCategory;

  final Map<String, List<String>> _categoryOptions = {
    'Men': ['T-shirt', 'Short', 'Nightpant'],
    'Women': ['Dress', 'Blouse', 'Skirt'],
    'Kids': ['Shirt', 'Pants', 'Shorts']
  };

  // Pick images from gallery
  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _images = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  // Save product to Firestore
  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      loadingDialog.showDefaultLoading("Uploading product");
      _formKey.currentState!.save();

      // Create a unique product ID
      productId = _uuid.v4();

      // Upload images to Firebase Storage and get the download URLs
      List<String> imageUrls = await _uploadImagesToStorage();

      // Save product details to Firestore
      Map<String,dynamic> data = {
        'name': _name,
        'description': _description,
        'price': _price,
        'discount': _discount,
        'sizes': _sizes,
        'colors': _colors.map((color) => color.value.toString()).toList(),
        'media': imageUrls,
        'productId': productId,
        'category': _selectedCategory,
        'subCategory': _selectedSubCategory,
      };

      DocumentReference documentReference= FirebaseFirestore.instance.doc("/SHOPS/DRESSSHOP/$_selectedCategory/$productId");
      await fireStoreService.uploadMapDataToFirestore(data, documentReference);

      // Clear the form
      _formKey.currentState!.reset();
      setState(() {
        _images.clear();
        _sizes.clear();
        _colors.clear();
        _selectedCategory = null;
        _selectedSubCategory = null;
      });
      loadingDialog.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product uploaded successfully!')),
      );
    }
  }

// Upload images to Firebase Storage
  Future<List<String>> _uploadImagesToStorage() async {
    List<String> imageUrls = [];
    int count = 1;

    for (File image in _images) {
      String filePath = "DressShopImages/$productId/";
      // Use the helper method to upload the file
      String downloadUrl = await firebaseStorageHelper.uploadFile(image, filePath, count.toString());

      // Add the download URL to the list
      if (downloadUrl.isNotEmpty) {
        imageUrls.add(downloadUrl);
      } else {
        // Handle error if necessary
        print('Error uploading image $count');
      }

      count++;
    }

    return imageUrls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Category'),
                value: _selectedCategory,
                items: _categoryOptions.keys
                    .map((category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedSubCategory = null; // Reset the sub-category
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),

              // Sub-Category Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Sub-Category'),
                value: _selectedSubCategory,
                items: _selectedCategory == null
                    ? []
                    : _categoryOptions[_selectedCategory]!
                    .map((subCategory) => DropdownMenuItem<String>(
                  value: subCategory,
                  child: Text(subCategory),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a sub-category';
                  }
                  return null;
                },
              ),

              // Product Name
              TextFormField(
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the product name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),

              // Product Description
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 4,
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
              // Product Price
              TextFormField(
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the price';
                  }
                  return null;
                },
                onSaved: (value) {
                  _price = double.parse(value!);
                },
              ),

              // Product Discount
              TextFormField(
                decoration: InputDecoration(labelText: 'Discount (%)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the discount';
                  }
                  return null;
                },
                onSaved: (value) {
                  _discount = double.parse(value!);
                },
              ),

              // Product Sizes
              TextFormField(
                decoration: InputDecoration(labelText: 'Available Sizes (comma separated)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter available sizes';
                  }
                  return null;
                },
                onSaved: (value) {
                  _sizes = value!.split(',').map((size) => size.trim()).toList();
                },
              ),

              // Product Colors
              SizedBox(height: 20),
              Text('Available Colors'),
              Wrap(
                spacing: 10.0,
                children: _colors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _colors.remove(color);
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black),
                      ),
                    ),
                  );
                }).toList()
                  ..add(
                    GestureDetector(
                      onTap: () async {
                        // Pick a color
                        List<Color>? pickedColors = await _pickColors(context);
                        if (pickedColors != null) {
                          setState(() {
                            _colors.addAll(pickedColors.where((color) => !_colors.contains(color)));
                          });
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Icon(Icons.add),
                      ),
                    ),
                  ),
              ),

              // Product Images
              SizedBox(height: 20),
              Text('Product Images'),
              Wrap(
                spacing: 10.0,
                children: _images.map((image) {
                  return Stack(
                    children: [
                      Image.file(image, width: 100, height: 100, fit: BoxFit.cover),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _images.remove(image);
                            });
                          },
                          child: Icon(Icons.remove_circle, color: Colors.red),
                        ),
                      ),
                    ],
                  );
                }).toList()
                  ..add(
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
              ),

              // Submit Button
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  child: Text('Upload Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                    textStyle: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Pick multiple colors
  Future<List<Color>?> _pickColors(BuildContext context) async {
    List<Color> selectedColors = [];

    return showDialog<List<Color>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick colors'),
          content: SingleChildScrollView(
            child: MultipleChoiceBlockPicker(
              pickerColors: _colors,
              onColorsChanged: (colors) {
                selectedColors = colors;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Select'),
              onPressed: () {
                // Close the color picker and prevent the keyboard from showing
                FocusScope.of(context).requestFocus(FocusNode()); // Unfocus text fields
                Navigator.of(context).pop(selectedColors);
              },
            ),
          ],
        );
      },
    );
  }


}
