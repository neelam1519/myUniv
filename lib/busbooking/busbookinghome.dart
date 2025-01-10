
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:findany_flutter/busbooking/history.dart';
import 'package:url_launcher/url_launcher.dart';

import 'busbooking_home_provider.dart';

class BusBookingHome extends StatefulWidget {
  const BusBookingHome({super.key});

  @override
  State<BusBookingHome> createState() => _BusBookingHomeState();
}

class _BusBookingHomeState extends State<BusBookingHome> {
  BusBookingHomeProvider? busBookingHomeProvider;

  @override
  void initState() {
    super.initState();
    final busBookingHomeProvider = Provider.of<BusBookingHomeProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      busBookingHomeProvider
        ..fetchFromPlaces()
        ..initializeRazorpay()
        ..fetchAnnouncementText();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Bus Booking'),
          backgroundColor: Colors.green,
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BusBookedHistory()),
                );
              },
            ),
          ],
        ),
        body: Consumer<BusBookingHomeProvider>(
          builder: (context, busHomeProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    if (busHomeProvider.announcementText != null && busHomeProvider.announcementText!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
                        child: Linkify(
                          text: busHomeProvider.announcementText!,
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
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: busHomeProvider.selectedFrom,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String? newValue) async{
                        busHomeProvider.selectedFrom = newValue;
                        busHomeProvider.availableDates = [];
                        busHomeProvider.timings = [];
                        busHomeProvider.travelCost = null;
                        busHomeProvider.costController.text = 'N/A';
                        if (newValue != null && busHomeProvider.selectedTo != null) {
                          await busHomeProvider.fetchDetails(newValue, busHomeProvider.selectedTo!);
                        }
                      },
                      items: busHomeProvider.fromPlaces.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: busHomeProvider.selectedTo,
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String? newValue) async{
                        setState(() {
                          busHomeProvider.selectedTo = newValue;
                          busHomeProvider.availableDates = [];
                          busHomeProvider.timings = [];
                          busHomeProvider.travelCost = null;
                          busHomeProvider.costController.text = 'N/A';
                        });
                        if (newValue != null && busHomeProvider.selectedFrom != null) {
                          await busHomeProvider.fetchDetails(busHomeProvider.selectedFrom!, newValue);
                        }
                      },
                      items: busHomeProvider.toPlaces.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: busHomeProvider.selectedDateFormatted,
                      decoration: const InputDecoration(
                        labelText: 'Select Date',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String? newValue) {
                        setState(() async{
                          busHomeProvider.selectedDateFormatted = newValue;
                          busHomeProvider.selectedDate = DateFormat('dd-MM-yyyy').parse(newValue!);
                          await busHomeProvider.updateTimingsForSelectedDate();
                        });
                      },
                      items: busHomeProvider.availableDates.map<DropdownMenuItem<String>>((String date) {
                        return DropdownMenuItem<String>(
                          value: date,
                          child: Text(date),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: busHomeProvider.selectedTiming,
                      decoration: const InputDecoration(
                        labelText: 'Timing',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String? newValue){
                        setState(() async {
                          busHomeProvider.selectedTiming = newValue;
                          await busHomeProvider.updateBusID();
                        });
                      },
                      items: busHomeProvider.timings.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number*',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          busHomeProvider.mobileNumber = value;
                        });
                      },
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Train No/Bus drop time',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          busHomeProvider.trainNo = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: busHomeProvider.people.length,
                      itemBuilder: (context, index) {
                        var person = busHomeProvider.people[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      person['name'] = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: person['gender'],
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      person['gender'] = newValue;
                                    });
                                  },
                                  items: ['M', 'F'].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async{
                                  await busHomeProvider.removePerson(index);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: busHomeProvider.addPerson,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Add Person'),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: busHomeProvider.costController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Cost per Person',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: busHomeProvider.totalCostController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Total Cost',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Seats: ${busHomeProvider.availableSeats}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (busHomeProvider.waitingListSeats > 0)
                          Text(
                            'Waiting List Seats: ${busHomeProvider.waitingListSeats}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        const SizedBox(height: 16.0),
                        if (busHomeProvider.message?.isNotEmpty ?? false)
                          Text(
                            busHomeProvider.message!,
                            style: const TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () async{
                        await busHomeProvider.searchBuses(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Book Ticket'),
                    ),
                    const SizedBox(height: 16.0),
                    Linkify(
                      text: busHomeProvider.contactus ?? '',
                      style: const TextStyle(color: Colors.red),
                      linkStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      onOpen: (link) async {
                        if (await canLaunch(link.url)) {
                          await launch(link.url);
                        } else {
                          throw 'Could not launch ${link.url}';
                        }
                      },
                    ),

                  ],
                ),
              ),
            );
          },
        ));
  }

  @override
  void dispose() {
    busBookingHomeProvider?.loadingDialog.dismiss();
    super.dispose();
  }
}
