import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';

class GroupChatProvider with ChangeNotifier {
  final SharedPreferences _sharedPreferences = SharedPreferences();
  final FireStoreService _fireStoreService = FireStoreService();
  final Utils _utils = Utils();

  List<Map<String, dynamic>> _chatGroups = [];
  bool shouldRefresh = true;

  LoadingDialog loadingDialog = LoadingDialog();
  List<Map<String, dynamic>> get chatGroups => _chatGroups;

  Future<void> fetchChatGroups() async {
    loadingDialog.showDefaultLoading("Getting Group...");
    try {

      _chatGroups = [];

      final chatGroupsSnapshot = await FirebaseFirestore.instance.collection('ChatGroups').get();
      if (chatGroupsSnapshot.docs.isEmpty) {
        return;
      }

      print('ChatGroups snapshot: ${chatGroupsSnapshot.docs}');
      chatGroupsSnapshot.docs.forEach((doc) {
        print('Processing document: ${doc.id}, data: ${doc.data()}');
      });


      final chatFutures = chatGroupsSnapshot.docs.map((document) async {
        final data = document.data();
        final groupName = data['GroupName'];

        if (groupName == 'App Testing') {
          return null;
        }

        final chatRef = rtdb.FirebaseDatabase.instance.ref().child("Chat/$groupName");

        // if (groupName != 'University Chat') {
        //   await _isFirstTime(groupName);
        // }

        final chatSnapshot = await chatRef.orderByKey().limitToLast(1).get();
        if (chatSnapshot.value != null) {
          final lastMessageMap = chatSnapshot.value as Map;
          final lastMessageData = Map<String, dynamic>.from(lastMessageMap.values.first);
          final lastMessage = lastMessageData['text'] ?? '';
          final createdAt = lastMessageData['createdAt'] ?? '';

          final createdAtDate = DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now();
          final formattedTime = _formatTime(createdAtDate);
          print('Current group name: $groupName, Profile URL: ${data['ProfileUrl']}');


          return {
            'groupName': groupName,
            'profileUrl': data['ProfileUrl'] ?? '',
            'lastMessage': lastMessage,
            'formattedTime': formattedTime,
            'createdAt': createdAtDate,
          };

        } else {
          return {
            'groupName': groupName,
            'profileUrl': data['ProfileUrl'] ?? '',
            'lastMessage': '',
            'formattedTime': '',
            'createdAt': DateTime.fromMillisecondsSinceEpoch(0),
          };
        }

      }).toList();

      _chatGroups = (await Future.wait(chatFutures)).where((group) => group != null).map((group) => group!).toList();
      _chatGroups.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching chat groups: $e');
      }
    }
    loadingDialog.dismiss();
  }


  Future<void> _subscribeToChat(String chatName) async {
    chatName = chatName.replaceAll(" ", "");
    final userRef = FirebaseFirestore.instance.doc('UserDetails/${_utils.getCurrentUserUID()}');
    final regNo = await _sharedPreferences.getDataFromReference(userRef, "Registration Number");
    final groupRef = FirebaseFirestore.instance.doc('ChatGroups/$chatName');
    final data = {"MEMBERS": FieldValue.arrayUnion([regNo])};
    await _fireStoreService.uploadMapDataToFirestore(data, groupRef);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    if (dateTime.isAfter(today)) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (dateTime.isAfter(yesterday)) {
      return 'Yesterday, ${DateFormat('hh:mm a').format(dateTime)}';
    } else if (dateTime.isAfter(twoDaysAgo)) {
      return DateFormat('MM/dd/yyyy, hh:mm a').format(dateTime);
    } else {
      return DateFormat('MM/dd/yyyy, hh:mm a').format(dateTime);
    }
  }
}
