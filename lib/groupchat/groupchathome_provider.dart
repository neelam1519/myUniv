import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class GroupChatHomeProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  List<Map<String,dynamic>> unJoinedGroups = [];
  Map<String, Map<String, dynamic>> roomMessages = {};
  bool isLoading = true;
  bool isAdmin = false;
  FireStoreService fireStoreService = FireStoreService();

  Utils utils = Utils();

  int get selectedIndex => _selectedIndex;

  Future<void> checkAdminStatus() async {
    try {
      final currentUser = await FirebaseChatCore.instance.firebaseUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      isAdmin = userDoc.exists && userDoc.data()?['role'] == 'admin';
      notifyListeners();
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  Future<void> fetchUnJoinedGroups() async {
    print("Running fetchUnJoinedGroups");
    isLoading = true; // Set loading state at the beginning
    try {
      CollectionReference collectionReference = FirebaseFirestore.instance.collection("rooms");

      // Fetch all documents in one go
      QuerySnapshot querySnapshot = await collectionReference.get();
      List<Map<String, dynamic>> allRooms = [];

      // Process each document in the snapshot
      for (var doc in querySnapshot.docs) {
        print('Document ID: ${doc.id}');
        Map<String, dynamic> roomData = doc.data() as Map<String, dynamic>;
        roomData['id'] = doc.id; // Add document ID to the room data
        allRooms.add(roomData);
      }

      final currentUser  = await FirebaseChatCore.instance.firebaseUser ;
      String uid = currentUser !.uid;
      print("Current User ID: $uid");

      // Filter unjoined groups
      unJoinedGroups = allRooms.where((map) {
        List<String> userIds = List<String>.from(map['userIds'] ?? []);
        bool isUnjoined = !userIds.contains(uid);
        if (isUnjoined) {
          print("Unjoined Group Found: ${map['id']}");
        }
        return isUnjoined;
      }).toList();

      print("Unjoined Groups: $unJoinedGroups");
    } catch (e) {
      print('Error fetching groups: $e');
    } finally {
      isLoading = false; // Ensure loading state is reset
      notifyListeners(); // Uncomment if using a state management solution
    }
  }

  Future<List<String>> fetchRoomData(String roomId) async {
    DocumentSnapshot roomSnapshot = await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
    List<String> userIds = [];
    if (roomSnapshot.exists) {
      Map<String, dynamic> roomData = roomSnapshot.data() as Map<String, dynamic>;
      userIds = List<String>.from(roomData['userIds']);
      print('UserIds: $userIds');
    }
    return userIds;
  }

  Future<void> joinGroup(String roomid) async {
    try {
      final currentUser = await FirebaseChatCore.instance.firebaseUser;
      if (currentUser == null) {
        throw Exception('Current user is not available');
      }

      for (Map<String, dynamic> map in unJoinedGroups) {
        if (map['id'] == roomid) {
          // Get the reference to the Firestore document
          DocumentReference documentReference = FirebaseFirestore.instance.doc("rooms/${map["id"]}");

          // Add the current user's UID to the 'usersIds' array field
          await documentReference.update({
            'userIds': FieldValue.arrayUnion([currentUser.uid])
          });

          // Remove the group from unJoinedGroups
          unJoinedGroups.remove(map);
          break; // Exit loop after finding and updating the group
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error joining group: $e');
    }
  }


  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  String getLastMessage(String roomId) {
    return roomMessages[roomId]?['lastMessage'] ?? 'No messages yet';
  }

  String getLastMessageTime(String roomId) {
    final timestamp = roomMessages[roomId]?['lastMessageTime'];
    if (timestamp == null) return 'No time';
    return '${timestamp.hour}:${timestamp.minute}';
  }

  void clearList(){
    unJoinedGroups.clear();
    print('Un Joined Groups: $unJoinedGroups');
  }
}
