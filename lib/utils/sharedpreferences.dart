import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SharedPreferences{
  final storage = const FlutterSecureStorage();

  Future<dynamic> getDataFromReference(DocumentReference documentReference, String key) async {
    String? data = await getSecurePrefsValue(key);
    if (data != null) {
      print('Data found in SharedPreferences for key: $key $data');
      return data;
    } else {
      print('Data not found in SharedPreferences for key: $key, fetching from Firestore...');
      try {
        DocumentSnapshot snapshot = await documentReference.get();
        if (snapshot.exists) {
          Map<String, dynamic>? firestoreData = snapshot.data() as Map<String, dynamic>?;
          print('Firestore Data: $firestoreData');
          if (firestoreData != null && firestoreData.containsKey(key)) {
            dynamic value = firestoreData[key];
            if (value != null) {
              await storeValueInSecurePrefs(key, value.toString());
              print('Data stored in SharedPreferences for key: $key');
              return value;
            }
          }
        }
        print('Data not found in Firestore for key: $key');
        return null;
      } catch (e) {
        print('Error fetching data from Firestore: $e');
        return null;
      }
    }
  }


  Future<void> storeMapValuesInSecureStorage(Map<String, dynamic> mapValues) async {
    try {
      for (MapEntry<String, dynamic> entry in mapValues.entries) {
        String key = entry.key;
        String value = entry.value.toString();

        await storage.write(key: key, value: value);
        print('$key :  $value');
      }
      print('Map values stored in secure storage successfully!');
    } catch (error) {
      print('Error storing map values: $error');
    }
  }

  Future<void> storeListInSecureStorage(List<String> yourList, String key) async {
    try {
      String jsonString = jsonEncode(yourList);
      await storage.write(key: key, value: jsonString);
      print('List stored in secure storage successfully!');
    } catch (error) {
      print('Error storing list: $error');
    }
  }

  Future<List<String>> getListFromSecureStorage(String key) async {
    try {
      String? jsonString = await storage.read(key: key);

      if (jsonString == null) {
        return [];
      }
      List<dynamic> jsonList = jsonDecode(jsonString);
      List<String> yourList = jsonList.cast<String>();
      print('List retrieved from secure storage successfully!');
      return yourList;
    } catch (error) {
      print('Error retrieving list: $error');
      return [];
    }
  }


  Future<dynamic> getSecurePrefsValue(String key) async {
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
      return;
    }
  }

}