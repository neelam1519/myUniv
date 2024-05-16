import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_database/firebase_database.dart';

class RealTimeDatabase {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.reference();

  Future<void> updateTypingStatus(ChatUser chatUser, String userId) async {
    try {
      String path = 'UniversityChat/$userId/';

      await _databaseReference.child(path).set(chatUser.toJson());

    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  Future<List<ChatUser>> getAllChatUserIds() async {
    try {
      String path = 'UniversityChat';
      List<ChatUser> chatUsersList = []; // Store the user IDs

      DatabaseReference ref = FirebaseDatabase.instance.ref(path);
      DatabaseEvent event = await ref.once();
      DataSnapshot dataSnapshot = event.snapshot;

      if (dataSnapshot.exists) {
        Map<dynamic, dynamic> data = dataSnapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          print('User ID: $key');
          print('First Name: ${value['firstName']}');
          print('Profile Image URL: ${value['profileImage']}');
          print('---');

          chatUsersList.add(
            ChatUser(
              id: value['id'],
              firstName: value['firstName'],
            ),
          );
        });
      } else {
        print('DataSnapShot Does not exist');
      }

      print('Chatting Users List: $chatUsersList');
      return chatUsersList;
    } catch (e) {
      print('Error fetching all chat user IDs: $e');
      rethrow;
    }
  }


  Future<void> removeTypingStatus(String userId) async {
    try {
      String path = 'UniversityChat/$userId/';
      await _databaseReference.child(path).remove();
    } catch (e) {
      print('Error removing typing status: $e');
    }
  }

  Future<int?> incrementValue(String location) async {
    try {
      // Get the data snapshot from the specified location
      DatabaseEvent event = await _databaseReference.child(location).once();
      DataSnapshot dataSnapshot = event.snapshot;

      if (!dataSnapshot.exists) {
        // If the location doesn't exist, create it with an initial value of 0
        await _databaseReference.child(location).set(1);
        return 1;
      } else {
        // Get the current value from the data snapshot
        int currentValue = dataSnapshot.value as int? ?? 0;

        // Increment the value
        int newValue = currentValue + 1;

        // Update the value in the database
        await _databaseReference.child(location).set(newValue);

        print('Value in $location incremented successfully.');
        return newValue; // Return the new incremented value
      }
    } catch (e) {
      print('Error incrementing value: $e');
      return null; // Handle errors gracefully
    }
  }

  Future<int?> decrementValue(String location) async {
    try {
      // Get the data snapshot from the specified location
      DatabaseEvent event = await _databaseReference.child(location).once();
      DataSnapshot dataSnapshot = event.snapshot;

      if (!dataSnapshot.exists) {
        // If the location doesn't exist, create it with an initial value of 0
        await _databaseReference.child(location).set(0);
        return 0;
      } else {
        // Get the current value from the data snapshot
        int currentValue = dataSnapshot.value as int? ?? 0;

        // Decrement the value
        int newValue = currentValue - 1;

        // Update the value in the database
        await _databaseReference.child(location).set(newValue);

        print('Value in $location decremented successfully.');
        return newValue; // Return the new decremented value
      }
    } catch (e) {
      print('Error decrementing value: $e');
      return null; // Handle errors gracefully
    }
  }

  Future<dynamic> getCurrentValue(String location) async {
    try {
      final DatabaseReference locationRef = FirebaseDatabase.instance.ref(location); // Get reference
      DatabaseEvent event = await locationRef.once();

      if (event.snapshot.exists) {
        return event.snapshot.value;
      } else {
        return null; // Return null to indicate no data found
      }
    } catch (e) {
      print('Error fetching current value: $e');
      return null; // Handle errors gracefully
    }
  }
}
