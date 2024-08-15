import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/storage.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;

class MerchantUploadPage extends StatefulWidget {
  final DocumentSnapshot? documentSnapshot;

  MerchantUploadPage({required this.documentSnapshot});
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

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _sizesController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    loadingDialog.showDefaultLoading("Getting the product Details");

    if (widget.documentSnapshot != null && widget.documentSnapshot!.exists) {
      var data = widget.documentSnapshot!.data() as Map<String, dynamic>;
      _name = data['name'] ?? 'N/A';
      _description = data['description'] ?? 'N/A';
      _price = (data['price'] ?? 0).toDouble();
      _discount = (data['discount'] ?? 0).toDouble();
      _sizes = List<String>.from(data['sizes'] ?? []);
      _colors = (data['colors'] ?? [])
          .map<Color>((colorValue) => Color(int.parse(colorValue)))
          .toList();
      _selectedCategory = data['category'];
      _selectedSubCategory = data['subCategory'];
      productId = data['productId'] ?? _uuid.v4();

      // Convert media URLs to local files
      _colorImages = {};
      Map<String, dynamic> mediaUrls = data['media'] ?? {};
      print("Media Urls: $mediaUrls");

      for (var entry in mediaUrls.entries) {
        String color = entry.key;
        List<dynamic> urlList = entry.value;

        // Parse the color string into a Color object
        Color parsedColor = Color(int.parse(color));

        // Download the images from the URLs (assuming downloadImages accepts List<String>)
        List<File> files = await downloadImages(List<String>.from(urlList));

        // Store the list of files in a map with the color as the key
        _colorImages[parsedColor] = files;
      }

      // Set the values to the controllers
      _nameController.text = _name;
      _descriptionController.text = _description;
      _priceController.text = _price.toString();
      _discountController.text = _discount.toString();
      _sizesController.text = _sizes.join(', ');

    } else {
      productId = _uuid.v4();
    }
    setState(() {
      // To refresh UI
    });

    loadingDialog.dismiss();
  }

  Future<List<File>> downloadImages(List<dynamic> urls) async {
    print("Url List: $urls");
    List<File> files = [];
    for (String url in urls) {
      try {
        print('Attempting to download image from URL: $url');

        final response = await http.get(Uri.parse(url));
        print('Received response with status code: ${response.statusCode}');

        if (response.statusCode == 200) {
          // Get the temporary directory
          final directory = await getTemporaryDirectory();
          print('Temporary directory path: ${directory.path}');

          // Get file name from URL
          final fileName = Uri.parse(url).pathSegments.last;
          // Construct the correct file path
          final filePath = '${directory.path}/$fileName';
          print('Constructed file path: $filePath');

          final fileDirectory = Directory(filePath).parent; // Get the parent directory
          if (!await fileDirectory.exists()) {
            await fileDirectory.create(recursive: true);
            print('Directory created: ${fileDirectory.path}');
          } else {
            print('Directory already exists: ${fileDirectory.path}');
          }

          // Create the file
          final file = File(filePath);
          print('Creating file at: $filePath');

          // Write the response body to the file
          await file.writeAsBytes(response.bodyBytes);
          print('File written successfully at: $filePath');

          // Check if the file was created successfully
          if (await file.exists()) {
            files.add(file);
            print('File exists and was added to the list: $filePath');
          } else {
            print('Error: File not found after writing: $filePath');
          }
        } else {
          print('Failed to download image: $url, Status Code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error downloading image from URL $url: $e');
      }
    }
    // Ensure the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        // Update UI or state with the downloaded files
      });
    } else {
      print('Widget is no longer mounted, cannot call setState.');
    }
    return files;
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

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      loadingDialog.showDefaultLoading("Uploading product");
      _formKey.currentState!.save();
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
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _discountController.clear();
        _sizesController.clear();
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
          String filePath = "DressShopImages/$productId/${color.value}";
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _price = double.parse(value!);
                  },
                ),
                TextFormField(
                  controller: _discountController,
                  decoration: InputDecoration(labelText: 'Discount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a discount';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _discount = double.parse(value!);
                  },
                ),
                TextFormField(
                  controller: _sizesController,
                  decoration: InputDecoration(labelText: 'Sizes (comma separated)'),
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
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(labelText: 'Category'),
                  items: _categoryOptions.keys.map((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(key),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedCategory = value;
                      _selectedSubCategory = null; // Reset subcategory when category changes
                    });
                  },
                ),
                if (_selectedCategory != null)
                  DropdownButtonFormField<String>(
                    value: _selectedSubCategory,
                    decoration: InputDecoration(labelText: 'SubCategory'),
                    items: _categoryOptions[_selectedCategory]!.map((String subCategory) {
                      return DropdownMenuItem<String>(
                        value: subCategory,
                        child: Text(subCategory),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedSubCategory = value;
                      });
                    },
                  ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickColorAndImages,
                  child: Text('Add Color and Images'),
                ),
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
                        subtitle: Text(
                            '${_colorImages[color]?.length ?? 0} image(s) selected'),
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
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProduct,
                  child: Text('Save Product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
}
