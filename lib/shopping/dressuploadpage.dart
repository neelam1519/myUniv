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
  FirebaseStorageHelper firebaseStorageHelper = FirebaseStorageHelper();

  LoadingDialog loadingDialog = LoadingDialog();

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
    'Men': ['T-shirt', 'Short', 'Nightpant'],
    'Women': ['Dress', 'Blouse', 'Skirt'],
    'Kids': ['Shirt', 'Pants', 'Shorts']
  };

  // Pick a color and then pick images for that color
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

  // Pick a single color
  Future<Color?> _pickColor(BuildContext context) async {
    Color? selectedColor;
    return showDialog<Color?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: Colors.white,
              onColorChanged: (color) {
                selectedColor = color;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Select'),
              onPressed: () {
                Navigator.of(context).pop(selectedColor);
              },
            ),
          ],
        );
      },
    );
  }

  // Pick images for a specific color
  Future<List<File>> _pickImagesForColor(Color color) async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      return pickedFiles.map((file) => File(file.path)).toList();
    }
    return [];
  }

  // Save product to Firestore
  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      loadingDialog.showDefaultLoading("Uploading product");
      _formKey.currentState!.save();
      // Create a unique product ID
      productId = _uuid.v4();
      // Upload images for each color to Firebase Storage and get the download URLs
      Map<String, List<String>> colorImageUrls = await _uploadImagesToStorage();
      // Save product details to Firestore
      Map<String, dynamic> data = {
        'name': _name,
        'description': _description,
        'price': _price,
        'discount': _discount,
        'sizes': _sizes,
        'colors': _colors.map((color) => color.value.toString()).toList(),
        'media': colorImageUrls,  // Storing image URLs for each color
        'productId': productId,
        'category': _selectedCategory,
        'subCategory': _selectedSubCategory,
      };
      DocumentReference documentReference = FirebaseFirestore.instance.doc("/SHOPS/DRESSSHOP/$_selectedCategory/$productId");
      await fireStoreService.uploadMapDataToFirestore(data, documentReference);
      // Clear the form
      _formKey.currentState!.reset();
      setState(() {
        _colors.clear();
        _colorImages.clear();
        _sizes.clear();
        _selectedCategory = null;
        _selectedSubCategory = null;
      });
      loadingDialog.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product uploaded successfully!')),
      );
    }
  }

  // Upload images for each color to Firebase Storage
  Future<Map<String, List<String>>> _uploadImagesToStorage() async {
    Map<String, List<String>> colorImageUrls = {};
    for (Color color in _colors) {
      List<String> imageUrls = [];
      if (_colorImages[color] != null) {
        int count = 1;
        for (File image in _colorImages[color]!) {
          String filePath = "DressShopImages/$productId/${color.value}/$count";
          // Use the helper method to upload the file
          String downloadUrl = await firebaseStorageHelper.uploadFile(image, filePath, count.toString());
          // Add the download URL to the list
          if (downloadUrl.isNotEmpty) {
            imageUrls.add(downloadUrl);
          } else {
            // Handle error if necessary
            print('Error uploading image $count for color ${color.value}');
          }
          count++;
        }
      }
      colorImageUrls[color.value.toString()] = imageUrls;
    }
    return colorImageUrls;
  }

  // Remove an image from the list
  void _removeImage(Color color, int index) {
    setState(() {
      _colorImages[color]?.removeAt(index);
      if (_colorImages[color]?.isEmpty ?? true) {
        _colorImages.remove(color);
        _colors.remove(color);
      }
    });
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

              // Available Sizes
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

              // Color Picker with Image Uploader
              SizedBox(height: 20),
              Text('Colors & Images'),
              SizedBox(height: 10),
              ..._colors.map((color) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                      ),
                      title: Text('Images for this color:'),
                      subtitle: Text('${_colorImages[color]?.length ?? 0} image(s) selected'),
                    ),
                    Wrap(
                      spacing: 8.0,
                      children: _colorImages[color]?.asMap().entries.map((entry) {
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
                              child: GestureDetector(
                                onTap: () => _removeImage(color, index),
                                child: Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList() ??
                          [],
                    ),
                  ],
                );
              }).toList(),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _pickColorAndImages,
                  child: Text('Add Color & Images'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                    textStyle: TextStyle(fontSize: 18.0),
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
}
