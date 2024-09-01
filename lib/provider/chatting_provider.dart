import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter/material.dart';
import '../Firebase/firestore.dart';
import '../services/sendnotification.dart';
import '../utils/sharedpreferences.dart';
import '../utils/utils.dart';

class ChatProvider extends ChangeNotifier {
  final Utils utils = Utils();
  final NotificationService notificationService = NotificationService();
  final SharedPreferences sharedPreferences = SharedPreferences();
  final FireStoreService fireStoreService = FireStoreService();

  late rtdb.DatabaseReference _chatRef;
  late rtdb.DatabaseReference _onlineUsersRef;

  final List<ChatMessage> _messages = [];
  ChatUser? _user;
  final User? _firebaseUser = FirebaseAuth.instance.currentUser;
  String? _lastMessageKey;
  bool _isLoadingMore = false;
  bool _isInitialLoadComplete = false;
  late StreamSubscription<rtdb.DatabaseEvent> _messageSubscription;
  late StreamSubscription<rtdb.DatabaseEvent> _onlineUsersSubscription;
  int _onlineUsersCount = 0;

  List<String> _tokens = [];
  List<dynamic> _restrictedWords = [];

  DocumentReference? userRef;
  bool _isMember = false;
  String _regNo = "";
  String _chatName = "";

  // Getters
  List<ChatMessage> get messages => _messages;
  ChatUser? get user => _user;
  int get onlineUsersCount => _onlineUsersCount;
  bool get isMember => _isMember;
  String get chatName => _chatName;
  bool get isInitialLoadComplete => _isInitialLoadComplete;

  // Setters
  set chatRef(rtdb.DatabaseReference ref) {
    _chatRef = ref;
    notifyListeners();
  }

  set onlineUsersRef(rtdb.DatabaseReference ref) {
    _onlineUsersRef = ref;
    notifyListeners();
  }

  set chatName(String name) {
    _chatName = name.replaceAll(" ", "");
    notifyListeners();
  }

  set isMember(bool value){
    _isMember = value;
    notifyListeners();
  }

  Future<void> initializeUser() async {
    if (_firebaseUser != null) {
      String email = _firebaseUser.email!;
      String userId = utils.removeEmailDomain(email);
      userRef = FirebaseFirestore.instance.doc('UserDetails/${utils.getCurrentUserUID()}');

      String username = await sharedPreferences.getDataFromReference(userRef!, "Username") ?? '';
      String displayName = utils.removeTextAfterFirstNumber(_firebaseUser.displayName ?? 'Anonymous');
      String name = username.isNotEmpty ? username : (displayName.isNotEmpty ? displayName : 'Anonymous');

      _user = ChatUser(id: userId, firstName: name);
      notifyListeners();
    }
  }

  Future<void> checkMembershipStatus() async {
    if (_firebaseUser != null) {
      _regNo = await sharedPreferences.getDataFromReference(userRef!, "Registration Number");
      DocumentReference groupRef = FirebaseFirestore.instance.doc('ChatGroups/$_chatName');

      DocumentSnapshot groupSnapshot = await groupRef.get();
      if (groupSnapshot.exists) {
        Map<String, dynamic>? groupData = groupSnapshot.data() as Map<String, dynamic>?;
        if (groupData != null && groupData.containsKey('MEMBERS')) {
          List<dynamic> members = groupData['MEMBERS'];
          _isMember = members.contains(_regNo);
        } else {
          _isMember = false;
        }
      } else {
        _isMember = false;
      }
      notifyListeners();
    }
  }

  Future<void> isFirstTime() async{
    String key = "${chatName}isFirstTime";
    print('key $key');
    bool value = await utils.checkFirstTime(key);
    print('isFirstTime: $value');
    if(value){
      Map<String,dynamic> values = {"${chatName}isFirstTime": false};
      sharedPreferences.storeMapValuesInSecureStorage(values);
    }
  }


  Future<void> handleSend(ChatMessage message) async {
    print("Handling Send");
    if (_restrictedWords.isEmpty) {
      await fetchRestrictedWords();
    }

    bool containsRestrictedWord =
    _restrictedWords.any((word) => message.text.toLowerCase().contains(word.toLowerCase()));

    if (containsRestrictedWord) {
      utils.showToastMessage('Message contains restricted content');
      if (_messages.contains(message)) {
        _messages.remove(message);
        notifyListeners();
      }
      return;
    }

    await _sendMessageAndNotify(message);
  }

  Future<void> _sendMessageAndNotify(ChatMessage message) async {
    print(": $chatName");
      print('Tokens: $_tokens');
      if (chatName == "UniversityChat") {
        if(_tokens.isEmpty) {
          _tokens = await utils.getAllTokens();
        }
        print("Getting all tokens");
      } else {
        List<dynamic> members =[];
        if(_tokens.isEmpty) {
          members = await getSubscribers();
        }
        print("Members: $members");
        members.remove(_regNo);
        _tokens = await getTokensForMembers(members);
      }
    final newMessageRef = _chatRef.push();
    newMessageRef.set(message.toJson());

    await notificationService.sendNotification(_tokens, chatName, message.text, {"source": "Group Chat"});

    print('Tokens: $_tokens');
  }


  Future<void> fetchRestrictedWords() async {
    DocumentReference chatRef = FirebaseFirestore.instance.doc('/ChatDetails/Restricted');
    DocumentSnapshot snapshot = await chatRef.get();

    if (snapshot.exists && snapshot.data() != null) {
      Map<String, dynamic> details = snapshot.data() as Map<String, dynamic>;
      _restrictedWords = List<String>.from(details["RestrictedWords"]);
    } else {
      _restrictedWords = [];
    }
    notifyListeners();
  }

  // Listen to Messages
  void listenForNewMessages() {
    _messageSubscription = _chatRef.orderByKey().limitToLast(20).onChildAdded.listen((event) {
      rtdb.DataSnapshot snapshot = event.snapshot;
      var value = snapshot.value;
      if (value is Map) {
        try {
          Map<String, dynamic> messageData = _convertToMapStringDynamic(value);
          _messages.insert(0, ChatMessage.fromJson(messageData));
          print("Messages: ${_messages.length}");
          print("Messages: ${_messages}");

          _lastMessageKey = snapshot.key;
          notifyListeners();
        } catch (e) {
          print("Error parsing new message: $e");
        }
      }
    });

    _chatRef.once().then((event) {
      _isInitialLoadComplete = true;
      notifyListeners();
    }).catchError((error) {
      _isInitialLoadComplete = true;
      notifyListeners();
    });
  }

  // Track Online Users
  void trackOnlineUsers() {
    _onlineUsersSubscription = _onlineUsersRef.onValue.listen((event) {
      rtdb.DataSnapshot snapshot = event.snapshot;
      if (snapshot.exists) {
        Map<dynamic, dynamic> onlineUsers = snapshot.value as Map<dynamic, dynamic>;
        _onlineUsersCount = onlineUsers.length;
      } else {
        _onlineUsersCount = 0;
      }
      notifyListeners();
    });
  }

  void setUserOnline() {
    if (_firebaseUser != null) {
      String userId = _firebaseUser.uid;
      _onlineUsersRef.child(userId).set(true);
      _onlineUsersRef.child(userId).onDisconnect().remove();
    }
  }

  void setUserOffline() {
    if (_firebaseUser != null) {
      String userId = _firebaseUser.uid;
      _onlineUsersRef.child(userId).remove();
    }
  }

  // Load More Messages
  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || _lastMessageKey == null) return;

    _isLoadingMore = true;
    notifyListeners();

    rtdb.Query query = _chatRef.orderByKey().endAt(_lastMessageKey).limitToLast(21);
    try {
      rtdb.DatabaseEvent event = await query.once();
      rtdb.DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        List<ChatMessage> moreMessages = [];
        String? newLastMessageKey;
        for (var childSnapshot in snapshot.children) {
          var value = childSnapshot.value;
          if (value is Map) {
            try {
              Map<String, dynamic> messageData = _convertToMapStringDynamic(value);
              ChatMessage chatMessage = ChatMessage.fromJson(messageData);
              if (childSnapshot.key != _lastMessageKey) {
                moreMessages.add(chatMessage);
              }
              newLastMessageKey = newLastMessageKey ?? childSnapshot.key;
            } catch (e) {
              print("Error parsing message: $e");
            }
          }
        }

        _messages.addAll(moreMessages.reversed.toList());
        _lastMessageKey = newLastMessageKey;
        notifyListeners();
      }
    } catch (error) {
      print("Error loading more messages: $error");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> getSubscribers() async {
    DocumentReference chatRef = FirebaseFirestore.instance.doc('/ChatGroups/$_chatName');
    Map<String, dynamic>? details = await fireStoreService.getDocumentDetails(chatRef);
    List<dynamic> members = details!["MEMBERS"];
    return members;
  }

  Future<List<String>> getTokensForMembers(List<dynamic> members) async {
    List<String> tokens = [];
    DocumentReference tokenRef = FirebaseFirestore.instance.doc('Tokens/Tokens');

    DocumentSnapshot docSnapshot = await tokenRef.get();
    if (docSnapshot.exists) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

      for (var member in members) {
        if (data.containsKey(member)) {
          tokens.add(data[member].toString());
        }
      }
    }

    return tokens;
  }

  Map<String, dynamic> _convertToMapStringDynamic(Map<dynamic, dynamic> original) {
    return original.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _convertToMapStringDynamic(value));
      } else {
        return MapEntry(key.toString(), value);
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    _onlineUsersSubscription.cancel();
    setUserOffline();
    super.dispose();
  }
}

