import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Chatting extends StatefulWidget {
  static bool isChatOpen = false;
  final rtdb.DatabaseReference chatRef;
  final rtdb.DatabaseReference onlineUsersRef;
  final String chatName;

  Chatting({
    required this.chatRef,
    required this.onlineUsersRef,
    required this.chatName,
  });

  @override
  _ChattingState createState() => _ChattingState();
}

class _ChattingState extends State<Chatting> {
  Utils utils = Utils();
  NotificationService notificationService = NotificationService();
  SharedPreferences sharedPreferences = SharedPreferences();
  FireStoreService fireStoreService = FireStoreService();

  late rtdb.DatabaseReference _chatRef;
  late rtdb.DatabaseReference _onlineUsersRef;
  List<ChatMessage> _messages = [];
  ChatUser? _user;
  User? firebaseUser = FirebaseAuth.instance.currentUser;
  String? _lastMessageKey;
  bool _isLoadingMore = false;
  bool _isInitialLoadComplete = false;
  late StreamSubscription<rtdb.DatabaseEvent> _messageSubscription;
  late StreamSubscription<rtdb.DatabaseEvent> _onlineUsersSubscription;
  int _onlineUsersCount = 0;

  List<String> tokens = [];
  List<dynamic> restrictedWords = [];

  DocumentReference? userRef;
  bool isMember = false;
  String regNo= "";
  String chatName = "";

  @override
  void initState() {
    super.initState();
    _chatRef = widget.chatRef;
    _onlineUsersRef = widget.onlineUsersRef;
    chatName = widget.chatName.replaceAll(" ", "");
    Chatting.isChatOpen = true;
    initializeUser().then((_) {
      if(chatName =="UniversityChat"){
        isMember = true;
      }else{
        checkMembershipStatus();
        isFirstTime();
      }
      fetchRestrictedWords();
      listenForNewMessages();
      trackOnlineUsers();
      setUserOnline();
    });


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

  void subscribeToChat() async {
    String regNo = await sharedPreferences.getDataFromReference(userRef!, "Registration Number");
    DocumentReference groupRef = FirebaseFirestore.instance.doc('ChatGroups/$chatName');
    isMember = true;

    Map<String, dynamic> data = {"MEMBERS": FieldValue.arrayUnion([regNo])};
    fireStoreService.uploadMapDataToFirestore(data, groupRef);

    setState(() {
      isMember = true;
    });
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    _onlineUsersSubscription.cancel();
    setUserOffline();
    Chatting.isChatOpen = false;
    super.dispose();
  }

  Future<void> initializeUser() async {
    if (firebaseUser != null) {
      String email = firebaseUser!.email!;
      String userId = utils.removeEmailDomain(email);
      userRef = FirebaseFirestore.instance.doc('UserDetails/${utils.getCurrentUserUID()}');

      String username = await sharedPreferences.getDataFromReference(userRef!, "Username") ?? '';
      String displayName = utils.removeTextAfterFirstNumber(firebaseUser!.displayName ?? 'Anonymous');
      String name = username.isNotEmpty ? username : (displayName.isNotEmpty ? displayName : 'Anonymous');

      if (mounted) {
        setState(() {
          _user = ChatUser(
            id: userId,
            firstName: name,
          );
        });
      }
    }
  }

  Future<void> checkMembershipStatus() async {
    if (firebaseUser != null) {
      print("Entered Membership Status");
      regNo = await sharedPreferences.getDataFromReference(userRef!, "Registration Number");
      DocumentReference groupRef = FirebaseFirestore.instance.doc('ChatGroups/$chatName');

      print('Registration Number: $regNo   ChatName: $chatName');

      DocumentSnapshot groupSnapshot = await groupRef.get();
      if (groupSnapshot.exists) {
        Map<String, dynamic>? groupData = groupSnapshot.data() as Map<String, dynamic>?;
        if (groupData != null && groupData.containsKey('MEMBERS')) {
          List<dynamic> members = groupData['MEMBERS'];
          print('Group Members: $members');
          setState(() {
            isMember = members.contains(regNo);
          });
        } else {
          print('MEMBERS field does not exist in the group document');
          setState(() {
            isMember = false;
          });
        }
      } else {
        print('Group document does not exist');
        setState(() {
          isMember = false;
        });
      }
    }
  }


  void listenForNewMessages() {
    print('Listening For New Messages...');
    List<String?> keyList = [];
    _messageSubscription = _chatRef.orderByKey().limitToLast(20).onChildAdded.listen((event) {
      if (!mounted) return;
      rtdb.DataSnapshot snapshot = event.snapshot;
      var value = snapshot.value;
      keyList.add(snapshot.key);
      if (value is Map) {
        try {
          Map<String, dynamic> messageData = _convertToMapStringDynamic(value);
          if (mounted) {
            setState(() {
              _messages.insert(0, ChatMessage.fromJson(messageData));
            });
          }
        } catch (e) {
          print("Error parsing new message: $e");
        }
      }
      _lastMessageKey = keyList.first;
      print('Last Message: $_lastMessageKey');
    });

    _chatRef.once().then((event) {
      if (!event.snapshot.exists) {
        if (mounted) {
          setState(() {
            _isInitialLoadComplete = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isInitialLoadComplete = true;
          });
        }
      }
    }).catchError((error) {
      print("Error fetching messages: $error");
      if (mounted) {
        setState(() {
          _isInitialLoadComplete = true;
        });
      }
    });
  }

  void trackOnlineUsers() {
    _onlineUsersSubscription = _onlineUsersRef.onValue.listen((event) {
      if (!mounted) return;
      rtdb.DataSnapshot snapshot = event.snapshot;
      if (snapshot.exists) {
        Map<dynamic, dynamic> onlineUsers = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _onlineUsersCount = onlineUsers.length;
        });
      } else {
        setState(() {
          _onlineUsersCount = 0;
        });
      }
    });
  }

  void setUserOnline() {
    if (firebaseUser != null) {
      String userId = firebaseUser!.uid;
      _onlineUsersRef.child(userId).set(true);
      _onlineUsersRef.child(userId).onDisconnect().remove();
    }
  }

  void setUserOffline() {
    if (firebaseUser != null) {
      String userId = firebaseUser!.uid;
      _onlineUsersRef.child(userId).remove();
    }
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || _lastMessageKey == null) return;

    if (mounted) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    print('Loading more messages from key: $_lastMessageKey');

    rtdb.Query query = _chatRef.orderByKey().endAt(_lastMessageKey).limitToLast(21);
    try {
      rtdb.DatabaseEvent event = await query.once();
      rtdb.DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        List<ChatMessage> moreMessages = [];
        String? newLastMessageKey;
        snapshot.children.forEach((childSnapshot) {
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
        });

        if (mounted) {
          setState(() {
            _messages.addAll(moreMessages.reversed.toList());
            _lastMessageKey = newLastMessageKey;
          });
        }
      }

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (error) {
      print("Error loading more messages: $error");
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> fetchRestrictedWords() async {
    DocumentReference chatRef = FirebaseFirestore.instance.doc('/ChatDetails/Restricted');
    DocumentSnapshot snapshot = await chatRef.get();

    if (snapshot.exists && snapshot.data() != null) {
      Map<String, dynamic> details = snapshot.data() as Map<String, dynamic>;
      restrictedWords = List<String>.from(details["RestrictedWords"]);
      print('Restricted Words: $restrictedWords');
    } else {
      print('Restricted words document does not exist or is empty.');
    }
  }

  Future<void> _handleSend(ChatMessage message) async {
    if (restrictedWords.isEmpty) {
      await fetchRestrictedWords();
    }

    bool containsRestrictedWord = restrictedWords.any((word) => message.text.toLowerCase().contains(word.toLowerCase()));

    if (containsRestrictedWord) {
      utils.showToastMessage('Message contains restricted content', context);
      if (mounted) {
        setState(() {
          _messages.remove(message);
        });
      }
      return;
    }

    await _sendMessageAndNotify(message);
  }

  Future<void> _sendMessageAndNotify(ChatMessage message) async {

    if(tokens.isEmpty) {
      print('Tokens: $tokens');
      if (chatName == "UniversityChat") {
        tokens = await utils.getAllTokens();
      } else {
        List<dynamic> members = await getSubscribers();
        members.remove(regNo);
        tokens = await getTokensForMembers(members);
      }
    }

    final newMessageRef = _chatRef.push();
    newMessageRef.set(message.toJson());
    await notificationService.sendNotification(tokens, widget.chatName, message.text, {"source": "Group Chat"});

    print('Tokens: $tokens');
  }

  Future<List<dynamic>> getSubscribers() async {
    DocumentReference chatRef = FirebaseFirestore.instance.doc('/ChatGroups/$chatName');
    Map<String, dynamic>? details = await fireStoreService.getDocumentDetails(chatRef);
    List<dynamic> members = details!["MEMBERS"];

    print('Members: $members');

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

    print('Tokens: $tokens');
    return tokens;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        actions: [
          if (chatName != "UniversityChat")
            IconButton(
              icon: Icon(
                isMember ? Icons.group_remove : Icons.group_add,
                color: isMember ? Colors.red : Colors.green,
              ),
              onPressed: () async {
                String regNo = await sharedPreferences.getDataFromReference(userRef!, "Registration Number");
                DocumentReference groupRef = FirebaseFirestore.instance.doc('ChatGroups/$chatName');

                if (isMember) {
                  DocumentSnapshot groupSnapshot = await groupRef.get();
                  if (groupSnapshot.exists) {
                    Map<String, dynamic>? groupData = groupSnapshot.data() as Map<String, dynamic>?;
                    if (groupData != null && groupData.containsKey('MEMBERS')) {
                      List<dynamic> members = List.from(groupData['MEMBERS']);
                      members.remove(regNo);
                      await groupRef.update({'MEMBERS': members});
                      print('Removed $regNo from MEMBERS list');
                    } else {
                      print('MEMBERS field does not exist in the group document');
                    }
                  } else {
                    print('Group document does not exist');
                  }
                  utils.showToastMessage('Removed from the group', context);
                  print('Removed from the group');
                } else {
                  Map<String, dynamic> data = {"MEMBERS": FieldValue.arrayUnion([regNo])};
                  fireStoreService.uploadMapDataToFirestore(data, groupRef);
                  utils.showToastMessage('Added to the group', context);
                  print('Added to the group');
                }

                setState(() {
                  isMember = !isMember;
                });
              },
            ),
          if (_onlineUsersCount > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 12),
                  SizedBox(width: 5),
                  Text('$_onlineUsersCount'),
                ],
              ),
            ),
        ],
      ),
      body: _user == null
          ? Center(child: CircularProgressIndicator())
          : !_isInitialLoadComplete
          ? Center(child: CircularProgressIndicator())
          : DashChat(
        currentUser: _user!,
        onSend: _handleSend,
        messages: _messages,
        readOnly: !isMember,
        messageListOptions: MessageListOptions(
          onLoadEarlier: loadMoreMessages,
        ),
        inputOptions: InputOptions(),
        messageOptions: MessageOptions(
          showTime: true,
          parsePatterns: [
            MatchText(
              type: ParsedType.URL,
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              onTap: (url) async {
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
            ),
          ],
        ),
      ),
    );
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
}
