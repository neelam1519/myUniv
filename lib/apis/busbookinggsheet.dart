import 'dart:convert';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:gsheets/gsheets.dart';

class BusBookingGSheet {
  Utils utils = Utils();

  // Load credentials from assets
  Future<String> _loadCredentials() async {
    return await rootBundle.loadString('assets/findany-84c36-b2a3e1d26731.json');
  }

  Future<void> _initGSheets() async {
    final credentialsJson = await _loadCredentials();
    final credentials = json.decode(credentialsJson);
    gsheets = GSheets(credentials);
  }

  static const spreadsheetId = '1oprZrwQ7GF4GB2un5-XPpl8N7PKNjgJYtXy_YNbXr4A';
  static late GSheets gsheets;
  static late Worksheet sheet;

  // Initialize the worksheet with the busID
  Future<void> initializeSheet(String busID) async {
    await _initGSheets();
    final spreadsheet = await gsheets.spreadsheet(spreadsheetId);
    sheet = spreadsheet.worksheetByTitle(busID) ?? await spreadsheet.addWorksheet(busID);
  }

  // Update the Google Sheet with the booking data
  static Future<void> updateBusBookingSheet(Map<String, dynamic> bookingData, String busID) async {
    try {
      // Initialize the sheet for the busID
      await BusBookingGSheet().initializeSheet(busID);

      // Check if the sheet is empty by checking if the first row has any data
      final values = await sheet.values.allRows();
      if (values.isEmpty) {
        // Insert headers in the first row if the sheet is empty
        final headers = [
          'Booking ID', // Booking ID
          'Booking Time', // Booking Time
          'Email', // Email
          'Mobile Number', // Mobile Number
          'From', // From
          'TO', // To
          'Bus Date', // Bus Date
          'Bus Time', // Bus Time
          'Ticket Status',
          'Ticket Count', // Ticket Count
          'Total Amount', // Total Amount
          'Payment ID', // Payment ID
        ];
        await sheet.values.insertRow(1, headers);  // Insert headers at row 1 (first row)
      }

      // Format the data into a row to insert
      final row = [
        bookingData['Booking ID'], // Booking ID
        bookingData['Booking Time'].toString(), // Booking Time
        bookingData['Email'], // Email
        bookingData['Mobile Number'], // Mobile Number
        bookingData['From'], // From
        bookingData['TO'], // To
        bookingData['Bus Date'], // Bus Date
        bookingData['Bus Time'], // Bus Time
        bookingData['Ticket Status'], // Payment ID
        bookingData['Ticket Count'], // Ticket Count
        bookingData['Total Amount'], // Total Amount
        bookingData['Payment ID'], // Payment ID
      ];

      // Get the next available row index, accounting for the header row
      int nextRow = values.length + 1;  // Number of rows is the length of 'values'

      // If the sheet was empty, nextRow will be 1, so we need to insert at row 2
      if (values.isEmpty) {
        nextRow = 2; // Start inserting data from the second row
      }

      // Insert the data into the next available row
      await sheet.values.insertRow(nextRow, row);
      print("Successfully updated Google Sheet with the booking data.");
    } catch (e) {
      print("Error updating Google Sheet: $e");
    }
  }
}