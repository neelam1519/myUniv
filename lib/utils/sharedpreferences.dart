import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SharedPreferences{
  final storage = FlutterSecureStorage();

  Future<void> storeMapValuesInSecureStorage(Map<String, dynamic> mapValues) async {
    try {
      for (MapEntry<String, dynamic> entry in mapValues.entries) {
        String key = entry.key;
        String value = entry.value.toString(); // Convert dynamic value to string

        // Store each key-value pair in secure storage
        await storage.write(key: key, value: value);
        print('$key :  $value');
      }
      print('Map values stored in secure storage successfully!');
    } catch (error) {
      print('Error storing map values: $error');
      // Handle the error as needed
    }
  }

  Future<void> storeListInSecureStorage(List<String> yourList, String key) async {

    try {
      // Convert the list to a JSON string
      String jsonString = jsonEncode(yourList);

      // Store the JSON string in secure storage
      await storage.write(key: key, value: jsonString);

      print('List stored in secure storage successfully!');
    } catch (error) {
      print('Error storing list: $error');
      // Handle the error as needed
    }
  }

  Future<List<String>> getListFromSecureStorage(String key) async {
    try {
      // Get JSON string from secure storage
      String? jsonString = await storage.read(key: key);

      // If the stored value is null, return an empty list
      if (jsonString == null) {
        return [];
      }

      // Convert the JSON string to a list
      List<dynamic> jsonList = jsonDecode(jsonString);

      // Map the dynamic list to a list of strings
      List<String> yourList = jsonList.cast<String>();

      print('List retrieved from secure storage successfully!');
      return yourList;
    } catch (error) {
      print('Error retrieving list: $error');
      // Handle the error as needed
      return [];
    }
  }


  Future<String?> getSecurePrefsValue(String key) async {
    try {
      return await storage.read(key: key);
    } catch (error) {
      print('Error retrieving value from secure storage: $error');
      return null;
    }
  }

  Future<void> storeValueInSecurePrefs(String key,dynamic value) async {
    try {
      return await storage.write(key: key, value: value);
    } catch (error) {
      print('Error retrieving value from secure storage: $error');
      return null;
    }
  }

}