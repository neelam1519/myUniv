import 'package:cloud_firestore/cloud_firestore.dart';

class FireStoreService {
  Future<bool> uploadMapDataToFirestore(Map<String, dynamic> data, DocumentReference documentReference) async {
    try {
      await documentReference.set(data, SetOptions(merge: true));
      print('Map data uploaded successfully to Firestore!');
      return true;
    } on FirebaseException catch (e) {
      print('Firestore Error: ${e.code} - ${e.message}');
      // Handle specific Firestore errors
      if (e.code == 'permission-denied') {
        print('Permission denied: You do not have the necessary permissions to perform this action.');
      } else {
        // Handle other Firestore errors
      }
      return false;
    } catch (e) {
      print('Error uploading map data to Firestore: $e');
      // Handle generic error
      return false;
    }
  }

  Future<bool> updateMapDataToFirestore(Map<String, dynamic> data, DocumentReference documentReference) async {
    try {
      await documentReference.update(data);
      print('Map data set successfully in Firestore!');
      return true;
    } on FirebaseException catch (e) {
      print('Firestore Error: ${e.code} - ${e.message}');
      // Handle specific Firestore errors
      if (e.code == 'permission-denied') {
        print('Permission denied: You do not have the necessary permissions to perform this action.');
      } else {
        // Handle other Firestore errors
      }
      return false;
    } catch (e) {
      print('Error setting map data in Firestore: $e');
      // Handle generic error
      return false;
    }
  }

  Future<void> deleteDocument(DocumentReference documentReference) async {
    try {
      // Delete the document
      await documentReference.delete();
      print('Document deleted successfully');
    } catch (e) {
      print('Error deleting document: $e');
      // Handle any errors that occur during the deletion process
    }
  }

  Future<List<String>> getDocumentNames(CollectionReference collectionReference) async {
    try {
      // Query the Firestore collection
      QuerySnapshot querySnapshot = await collectionReference.get();

      // Extract document names from the query snapshot
      List<String> documentNames = querySnapshot.docs.map((doc) => doc.id).toList();

      return documentNames;
    } catch (e) {
      // Handle any errors that occur
      print('Error retrieving document names: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDocumentDetails(DocumentReference documentReference) async {
    try {
      // Get the document snapshot using the provided document reference
      DocumentSnapshot documentSnapshot = await documentReference.get();

      // Check if the document exists
      if (documentSnapshot.exists) {
        // Convert the document snapshot data to a map
        Map<String, dynamic> documentData = documentSnapshot.data() as Map<String, dynamic>;

        // Return the document details map
        return documentData;
      } else {
        // If document doesn't exist, return null
        return null;
      }
    } catch (error) {
      // Handle errors
      print('Error fetching document details: $error');
      return null;
    }
  }

  void deleteFieldsFromDocument(DocumentReference docRef, List<String> fieldNames) {
    Map<String, dynamic> updates = {};
    for (String fieldName in fieldNames) {
      updates[fieldName] = FieldValue.delete();
    }

    // Use update method to delete the fields
    docRef.update(updates).then((_) {
      print('Fields $fieldNames deleted successfully');
    }).catchError((error) {
      print('Error deleting fields $fieldNames: $error');
    });
  }

  Future<dynamic> getFieldValue(DocumentReference documentRef,String fieldName) async {
    try {

      // Get the document snapshot
      DocumentSnapshot documentSnapshot = await documentRef.get();

      // Check if the document exists
      if (documentSnapshot.exists) {
        // Return the value of the specific field
        return documentSnapshot.get(fieldName);
      } else {
        print("Document does not exist");
        return null;
      }
    } catch (e) {
      print("Error getting field value: $e");
      return null;
    }
  }
}
