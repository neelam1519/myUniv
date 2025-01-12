import 'package:findany_flutter/busbooking/buslist.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'busbooking_home_provider.dart';

class BusBookingHome extends StatefulWidget {
  const BusBookingHome({super.key});

  @override
  State<BusBookingHome> createState() => _BusBookingHomeState();
}

class _BusBookingHomeState extends State<BusBookingHome> {
  @override
  void initState() {
    super.initState();
    final busBookingHomeProvider = Provider.of<BusBookingHomeProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      busBookingHomeProvider.fetchBusDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Bus Booking',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 5,
      ),
      body: Consumer<BusBookingHomeProvider>(
        builder: (context, busHomeProvider, child) {

          return AnimationLimiter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 500),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    _buildDropdown(
                      label: 'From',
                      value: busHomeProvider.selectedFrom,
                      items: busHomeProvider.fromPlaces,
                      onChanged: (newValue) async {
                        await busHomeProvider.updateSelectedFrom(newValue);
                      },
                    ),
                    const SizedBox(height: 16.0),
                    _buildDropdown(
                      label: 'To',
                      value: busHomeProvider.selectedTo,
                      items: busHomeProvider.toPlaces,
                      onChanged: (newValue) async {
                        await busHomeProvider.updateSelectedTo(newValue);
                      },
                    ),
                    const SizedBox(height: 16.0),
                    _buildDateField(
                      label: 'Select Date',
                      selectedDate: DateFormat('dd-MM-yyyy').format(busHomeProvider.selectedDate), // Set today's date
                      onDateChanged: (newDate) async {
                        print('DateTIme: $newDate  ${newDate.runtimeType}');
                        await busHomeProvider.updateSelectedDate(newDate!);
                      },

                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: () async {

                        print("Selected: ${busHomeProvider.selectedFrom!}   ${busHomeProvider.selectedTo!}   ${busHomeProvider.selectedDate}");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  BusList(
                              fromLocation: busHomeProvider.selectedFrom!,
                              toLocation: busHomeProvider.selectedTo! ,
                              selectedDate: busHomeProvider.selectedDate ,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        'Search Buses',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required String selectedDate,
    required void Function(DateTime?) onDateChanged,
  }) {
    return TextFormField(
      controller: TextEditingController(text: selectedDate),
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(Icons.calendar_today),
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(), // Today as the initial date
              firstDate: DateTime.now(),    // Prevent past date selection
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              print('Picked Date: $pickedDate');
              onDateChanged(pickedDate);  // Update date in the provider
            }
          },
        ),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          print('Picked Date: $pickedDate');
          onDateChanged(pickedDate);
        }
      },
    );
  }

}
