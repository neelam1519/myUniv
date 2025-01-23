import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Firebase/firestore.dart';
import '../apis/razorpay.dart';
import '../utils/utils.dart';
import 'package:carousel_slider/carousel_slider.dart';

class TravelDetailsPage extends StatefulWidget {
  final Map<String, dynamic> busDetails;

  const TravelDetailsPage({Key? key, required this.busDetails}) : super(key: key);

  @override
  _TravelDetailsPageState createState() => _TravelDetailsPageState();
}

class _TravelDetailsPageState extends State<TravelDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _trainNumberController = TextEditingController();
  Utils utils = Utils();
  final List<Map<String, dynamic>> _passengers = [
    {'name': '', 'gender': 'M'}
  ];

  int availableSeats = 0;
  String url = '';
  bool _isTermsAccepted = false;
  int get ticketPrice => widget.busDetails['price'].round() ?? 0;
  List<dynamic> imageUrls = [];
  int get totalCost => _passengers.length * ticketPrice;
  FireStoreService fireStoreService = FireStoreService();

  @override
  void initState() {
    super.initState();
    availableSeats = widget.busDetails["availableSeats"];
    _listenToBusSeatUpdates();
    getTermsAndConditions();
  }

  Future<void> getTermsAndConditions() async {
    DocumentReference documentReference = FirebaseFirestore.instance.doc('buses/${widget.busDetails['busNumber']}');
    url = await fireStoreService.getFieldValue(documentReference, 'termsandconditions');
    imageUrls = await fireStoreService.getFieldValue(documentReference, 'imageUrls');
  }

  void _listenToBusSeatUpdates() {
    FirebaseFirestore.instance
        .collection('buses')
        .doc(widget.busDetails['busNumber'].toString())
        .snapshots()
        .listen((documentSnapshot) {
      if (documentSnapshot.exists) {
        final updatedBusData = documentSnapshot.data()!;
        setState(() {
          availableSeats = updatedBusData["availableSeats"];
        });
      }
    });
  }

  void _addPassenger() {
    if (_passengers.last['name'].isNotEmpty && availableSeats > 0) {
      setState(() {
        _passengers.add({'name': '', 'gender': 'M'});
      });
    } else if (availableSeats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more seats available!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the name of the current passenger!')),
      );
    }
  }

  void _removePassenger(int index) {
    setState(() {
      _passengers.removeAt(index);
    });
  }

  Future<void> _submitBooking() async {
    if (_formKey.currentState?.validate() == true) {
      String? email = await utils.getCurrentUserEmail();
      String mobileNumber = _contactController.text;

      if(!_isTermsAccepted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accept the Terms and conditions.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (utils.isValidMobileNumber(mobileNumber)) {
        final razorpay = RazorPayment();
        razorpay.initializeRazorpay(context);
        razorpay.startPayment(totalCost, _contactController.text, _trainNumberController.text, email!, widget.busDetails, _passengers);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid mobile number. Please enter a valid 10-digit number.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Book Your Journey',
            style: TextStyle(color: Colors.white),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bus Details Section
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.busDetails['from']} → ${widget.busDetails['to']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${widget.busDetails['arrivalDate']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Departure Time: ${widget.busDetails['departureTime']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Available Seats: $availableSeats',
                        style: const TextStyle(fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
              // Passenger Details Form
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Passenger Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._passengers.asMap().entries.map((entry) {
                      int index = entry.key;
                      var passenger = entry.value;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: passenger['name'],
                                  onChanged: (value) {
                                    setState(() {
                                      _passengers[index]['name'] = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Passenger ${index + 1} Name',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter a name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              DropdownButton<String>(
                                value: passenger['gender'],
                                onChanged: (value) {
                                  setState(() {
                                    passenger['gender'] = value!;
                                  });
                                },
                                items: ['M', 'F'].map((gender) {
                                  return DropdownMenuItem(
                                    value: gender,
                                    child: Text(gender),
                                  );
                                }).toList(),
                              ),
                              if (_passengers.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _removePassenger(index),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: _addPassenger,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Passenger'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a contact number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _trainNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Train Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your Train number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _showBusImages(context);
                      },
                      child: const Text('Check Bus Images'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Checkbox(
                          value: _isTermsAccepted,
                          onChanged: (value) {
                            setState(() {
                              _isTermsAccepted = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open Terms and Conditions.')),
                                );
                              }
                            },
                            child: const Text(
                              'I agree to the Terms and Conditions',
                              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(0, -2),
              blurRadius: 6.0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Cost: ₹$totalCost',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: _submitBooking,
              child: const Text('Book Tickets'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBusImages(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 30),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  padding: EdgeInsets.zero,
                  alignment: Alignment.topRight,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: CarouselSlider.builder(
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index, realIndex) {
                      return GestureDetector(
                        onTap: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          );
                          String filePath = await _downloadImage(imageUrls[index]);
                          Navigator.of(context).pop();
                          if (filePath.isNotEmpty) {
                            final result = await OpenFile.open(filePath);
                            if (result.type != ResultType.done) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not open the file: ${result.message}')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to download image')),
                            );
                          }
                        },
                        child: CachedNetworkImage(
                          imageUrl: imageUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      autoPlay: true,
                      enlargeCenterPage: true,
                      aspectRatio: 2.0,
                      initialPage: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _downloadImage(String imageUrl) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final dio = Dio();
      await dio.download(imageUrl, filePath);
      return filePath;
    } catch (e) {
      print('Error downloading image: $e');
      return '';
    }
  }
}