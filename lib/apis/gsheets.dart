import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:findany_flutter/utils/utils.dart';
import 'package:gsheets/gsheets.dart';

class UserSheetsApi {
  Utils utils = Utils();
  static late GSheets gsheets;
  static const spreadsheetId = '1Jdc6EDIewHSglogg3NqHA0XHeax_kVFIdg2NifBXtfs';
  static late Worksheet sheet;

  // Load credentials from assets
  Future<String> _loadCredentials() async {
    return await rootBundle.loadString('assets/findany-84c36-b2a3e1d26731.json');
  }

  Future<void> _initGSheets() async {
    final credentialsJson = await _loadCredentials();
    final credentials = json.decode(credentialsJson);
    gsheets = GSheets(credentials);
  }

  Future<void> main() async {
    // Ensure GSheets is initialized
    await _initGSheets();

    String todayDate = utils.getTodayDate();
    final ss = await gsheets.spreadsheet(spreadsheetId);

    Worksheet? existingSheet = ss.worksheetByTitle(todayDate);

    if (existingSheet == null) {
      existingSheet = await ss.addWorksheet(todayDate);
      await existingSheet.values.insertRow(1, ['ID','NAME', 'MOBILE NUMBER', 'EMAIL', 'BINDING', 'DOUBLE SIDE', 'TOTAL PRICE', 'DESCRIPTION', 'PAYMENT ID', 'DATA', 'NO OF FILES', 'FILES']);
    }
    sheet = existingSheet;
  }

  Future<void> updateCell(List<dynamic> value) async {
    await main();
    try {
      await sheet.values.appendRow(value);
    } catch (e) {
      print('Error updating cell: $e');
    }
  }

  // Add the addItem method
  Future<void> addXeroxItem(Map<String, dynamic> data) async {
    await main();
    try {
      List<dynamic> values = [
        data['name'],
        data['mobilenumber'],
        data['email'],
        data['bindingFile'],
        data['singleSideFile'],
        data['totalAmount'],
        data['description'],
        data['paymentId'],
        data['paymentSuccess'],
        data['timeStamp'],
        data['files']
      ];
      await sheet.values.appendRow(values);
    } catch (e) {
      print('Error adding item to sheet: $e');
    }
  }
}
