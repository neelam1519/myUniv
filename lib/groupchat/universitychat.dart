import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class UniversityChat extends StatefulWidget {
  @override
  _UniversityChatState createState() => _UniversityChatState();
}

class _UniversityChatState extends State<UniversityChat> {
  late SharedPreferences sharedPreferences;
  late FireStoreService fireStoreService;
  late RealTimeDatabase realTimeDatabase;
  late LoadingDialog loadingDialog;
  late Utils utils;

  final FocusNode _focusNode = FocusNode();

  FirebaseStorage storage = FirebaseStorage.instance;

  late Stream<QuerySnapshot> chattingStream;
  late Stream<QuerySnapshot> typingStream;
  late StreamGroup<QuerySnapshot<Object?>> mergedStream;

  Timer? _typingTimer;

  late ChatUser user;
  late List<ChatUser> typingUsers;
  late List<ChatMessage> messagesList;
  late List<ChatMedia> chatMedia;
  late List<String?> filePaths;
  late List<File> selectedFiles;
  late String name, email, regNo, profileUrl;

  int _messageBatchSize = 15;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;

  late List<dynamic> allMessages;
  late List<QuerySnapshot> snapshots;

  String hintText = 'Type your message';
  bool allMessagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    loadingDialog.showDefaultLoading('Getting Messages...');
    subscribeToUniversityChat();

    print('Last Document is null');
    chattingStream = FirebaseFirestore.instance
        .collection('Chatting')
        .orderBy('createdAt', descending: true)
        .limit(_messageBatchSize)
        .snapshots();

    typingStream = FirebaseFirestore.instance.collection('TypingDetails').snapshots();

    getDetails().then((_) {
      setState(() {
        user = ChatUser(
          id: regNo,
          firstName: name,
          profileImage: profileUrl,
        );
      });
    });
  }

  void _initializeServices() {
    user = ChatUser(id: '', firstName: '', profileImage: '');
    sharedPreferences = SharedPreferences();
    fireStoreService = FireStoreService();
    realTimeDatabase = RealTimeDatabase();
    loadingDialog = LoadingDialog();
    utils = Utils();
    typingUsers = [];
    messagesList = [];
    chatMedia = [];
    filePaths = [];
    selectedFiles = [];
    allMessages = [];
  }

  @override
  Widget build(BuildContext context) {
    print('Build is running');
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('University Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chattingStream,
              builder: (context, chattingSnapshot) {
                if (chattingSnapshot.hasError) {
                  return Text('Error: ${chattingSnapshot.error}');
                }
                if (!_isLoading && chattingSnapshot.hasData) {
                  print('Chatting Snapshot is running');
                  _processNewMessages(chattingSnapshot.data!);
                }
                return buildDashChat(messagesList, typingUsers);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _processNewMessages(QuerySnapshot data) {
    List<ChatMessage> newMessages = data.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      String dateTimeString = data['createdAt'];
      DateTime dateTime = DateTime.parse(dateTimeString);
      Map<String, dynamic> mapData = data['user'];
      ChatUser user = ChatUser.fromJson(mapData);

      List<ChatMedia> listMedia = [];
      List<dynamic>? mediaData = data['medias'];
      if (mediaData != null && mediaData.isNotEmpty) {
        for (Map<String, dynamic> mapMedia in mediaData) {
          listMedia.add(ChatMedia.fromJson(mapMedia));
        }
      }
      return ChatMessage(
        user: user,
        text: data['text'],
        medias: listMedia,
        createdAt: dateTime,
      );
    }).toList();

    if (data.docs.isNotEmpty) {
      _lastDocument = data.docs.last;
    }
    if (data.docs.isEmpty) {
      allMessagesLoaded = true;
    }

    messagesList.insertAll(0, newMessages);
    loadingDialog.dismiss();
  }

  Widget buildDashChat(List<ChatMessage> messages, List<ChatUser> typingUsers) {
    print('Building dash chat : ${messages.length}');
    return Column(
      children: [
        Expanded(
          child: DashChat(
            currentUser: user,
            onSend: _handleSendMessage,
            messageListOptions: MessageListOptions(onLoadEarlier: _loadEarlierMessages),
            messages: messages,
            inputOptions: InputOptions(
              alwaysShowSend: true,
              inputDecoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                hintText: hintText,
                suffixIcon: IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _pickFile,
                ),
              ),
              onTextChange: _handleTextChange,
            ),
            messageOptions: MessageOptions(
              messagePadding: EdgeInsets.all(10),
              showTime: true,
              messageTimeBuilder: (ChatMessage chatMessage, bool isOwnMessage) {
                return Padding(
                  padding: EdgeInsets.only(left: 40.0),
                  child: Text(
                    '${chatMessage.createdAt.hour}:${chatMessage.createdAt.minute}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 6.0,
                    ),
                  ),
                );
              },
              messageMediaBuilder: (ChatMessage message, ChatMessage? previousMessage, ChatMessage? nextMessage) {
                return buildMediaMessage(message.medias!);
              },
              onTapMedia: (ChatMedia media) {
                print('Media tapped: ${media.url}');
              },
            ),
            typingUsers: typingUsers,
          ),
        ),
        buildSelectedFilesWidget(),
      ],
    );
  }

  Future<void> _handleSendMessage(ChatMessage m) async {
    try {
      _isLoading = false;
      if (selectedFiles.isNotEmpty) {
        await _uploadFiles();
      }

      ChatMessage chatMessage = ChatMessage(
        user: user,
        createdAt: DateTime.now(),
        text: m.text,
        medias: List.from(chatMedia),
      );
      DocumentReference documentReference = FirebaseFirestore.instance.doc('Chatting/${Timestamp.now().microsecondsSinceEpoch.toString()}');
      await fireStoreService.uploadMapDataToFirestore(chatMessage.toJson(), documentReference);
      sendNotification('GroupChat', m.text);

      setState(() {
        hintText = 'Type your message';
        selectedFiles.clear();
        chatMedia.clear();
      });
    } catch (e) {
      loadingDialog.dismiss();
      print('Error sending message: $e');
      hintText = 'Enter the message';
      utils.showToastMessage('Error sending message', context);
    }
  }

  Future<void> _uploadFiles() async {
    loadingDialog.showDefaultLoading('Upload Files to chat');
    loadingDialog.showProgressLoading(0, 'Files are uploading');

    for (File file in selectedFiles) {
      String filepath = file.path;
      String filename = path.basename(filepath);
      String extension = utils.getFileExtension(File(filepath));

      Reference ref = storage.ref().child('ChatMedia').child('${utils.getCurrentUserUID()}').child('$filename');
      final UploadTask uploadTask = ref.putFile(File(filepath));

      final StreamSubscription<TaskSnapshot> streamSubscription = uploadTask.snapshotEvents.listen((event) {
        double progress = event.bytesTransferred / event.totalBytes;
        loadingDialog.showProgressLoading(progress, 'Uploading file $filename');
      });

      await uploadTask.whenComplete(() {
        streamSubscription.cancel();
      });

      final String downloadUrl = await ref.getDownloadURL();
      MediaType? mediaType = getMediaType(extension);
      chatMedia.add(ChatMedia(url: downloadUrl, fileName: filename, type: mediaType!));
    }

    loadingDialog.dismiss();
    utils.showToastMessage('Files uploaded', context);
  }

  void _handleTextChange(String value) async {
    DocumentReference documentReference = FirebaseFirestore.instance.doc('TypingDetails/${user.id}');
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 1), () {
      print('User stopped typing');
      fireStoreService.deleteDocument(documentReference);
    });
    Map<String, String> data = {'id': user.id, 'Name': user.firstName!};
    fireStoreService.uploadMapDataToFirestore(data, documentReference);
  }

  Widget buildSelectedFilesWidget() {
    return selectedFiles.isNotEmpty
        ? Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: selectedFiles.length,
        itemBuilder: (context, index) {
          String fileName = selectedFiles[index].path.split('/').last;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[300],
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFiles.removeAt(index);
                          });
                        },
                        child: _buildFilePreview(selectedFiles[index]),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFiles.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    )
        : SizedBox.shrink();
  }

  Future<void> _loadEarlierMessages() async {
    print('LoadEarlier Messages');

    Query query = FirebaseFirestore.instance
        .collection('Chatting')
        .orderBy('createdAt', descending: true)
        .limit(_messageBatchSize);

    if (_lastDocument != null) {
      print('LastDocument: ${_lastDocument!.id}');
      query = query.startAfterDocument(_lastDocument!);
    }
    print('Load Earlier messages: ${query.parameters}');
    try {
      QuerySnapshot querySnapshot = await query.get();

      List<ChatMessage> newMessages = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        String dateTimeString = data['createdAt'];
        DateTime dateTime = DateTime.parse(dateTimeString);

        Map<String, dynamic> mapData = data['user'];
        ChatUser user = ChatUser.fromJson(mapData);

        List<ChatMedia> listMedia = [];
        List<dynamic>? mediaData = data['medias'];
        if (mediaData != null && mediaData.isNotEmpty) {
          for (Map<String, dynamic> mapMedia in mediaData) {
            listMedia.add(ChatMedia.fromJson(mapMedia));
          }
        }

        return ChatMessage(
          text: data['text'],
          user: user,
          medias: listMedia,
          createdAt: dateTime,
        );
      }).toList();

      if (newMessages.isEmpty) {
        if (_lastDocument == null) {
          utils.showToastMessage('All Messages Loaded', context);
        }
      } else {
        setState(() {
          _isLoading = true;
          messagesList.addAll(newMessages);
          if (querySnapshot.docs.isNotEmpty) {
            _lastDocument = querySnapshot.docs.last;
          }
          print('All Messages length: ${messagesList.length}');
          print("MessageList: ${messagesList.map((element) => element.text).join(', ')}");
          print('New messages Messages length: ${newMessages.length}');
          print("New Messages: ${newMessages.map((element) => element.text).join(', ')}");
        });
      }
    } catch (error) {
      print("Error loading earlier messages: $error");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildMediaMessage(List<ChatMedia> medias) {
    print('All Messages: ${messagesList.length}');
    return Wrap(
      children: medias.map((media) {
        String fileName = extractFileName(media.url);
        print('Media name: $fileName');
        File file = File('/data/data/com.neelam.FindAny/cache/ChatDownload/$fileName');
        bool fileExists = file.existsSync();

        if (media.type == MediaType.image) {
          return InkWell(
            onTap: () async {
              print('Image tapped: ${media.url}');
              downloadAndOpenFile(media.url, fileName);
            },
            child: Container(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  Image.network(
                    media.url,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (fileExists)
                        Icon(
                          Icons.download_done,
                          color: Colors.green,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else if (media.type == MediaType.video) {
          return InkWell(
            onTap: () async {
              print('Video tapped: ${media.url}');
              downloadAndOpenFile(media.url, fileName);
            },
            child: Container(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  VideoPlayer(url: media.url),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (fileExists)
                        Icon(
                          Icons.download_done,
                          color: Colors.green,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else if (media.type == MediaType.file) {
          return InkWell(
            onTap: () async {
              print('File: ${media.url}');
              downloadAndOpenFile(media.url, fileName);
            },
            child: Container(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    size: 50,
                    color: Colors.grey[600],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (fileExists)
                        Icon(
                          Icons.download_done,
                          color: Colors.green,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          return Container();
        }
      }).toList(),
    );
  }

  String extractFileName(String url) {
    String decodedUrl = Uri.decodeFull(url);
    RegExp regExp = RegExp(r'[^\/]+(?=\?)');
    Match? match = regExp.firstMatch(decodedUrl);
    return match?.group(0) ?? '';
  }

  Widget _buildFilePreview(File file) {
    String extension = path.extension(file.path).toLowerCase();
    if (extension == '.pdf') {
      return Icon(Icons.picture_as_pdf, size: 50, color: Colors.red);
    } else if (extension == '.docx') {
      return Icon(Icons.insert_drive_file, size: 50, color: Colors.blue);
    } else {
      return Image.file(file, fit: BoxFit.cover);
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx'],
      );
      if (result != null) {
        hintText = 'Enter text about the files to send in chat';
        //utils.showToastMessage("Enter text about the files to send in chat", context);
        List<String?> filePaths = result.paths;
        List<File> files = filePaths.map((path) => File(path!)).toList();
        setState(() {
          selectedFiles.addAll(files);
        });
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  Future<void> getDetails() async {
    DocumentReference documentReference = FirebaseFirestore.instance.doc('/UserDetails/${utils.getCurrentUserUID()}');

    name = await sharedPreferences.getDataFromReference(documentReference,'Username') ?? (await sharedPreferences.getDataFromReference(documentReference,'Name')) ?? '';
    email = await sharedPreferences.getDataFromReference(documentReference,'Email') ?? '';
    regNo = await sharedPreferences.getDataFromReference(documentReference,'Registration Number') ?? '';
    profileUrl = await sharedPreferences.getDataFromReference(documentReference,'ProfileImageURL') ?? '';
    print('User Details $name  $email  $regNo  $profileUrl');
  }

  Future<void> sendNotification(String title, String message) async {
    Map<String, dynamic> additionalData = {'source': 'UniversityChat'};
    DocumentReference tokenRef = FirebaseFirestore.instance.doc('/Tokens/Tokens');
    NotificationService notificationService = NotificationService();
    Map<String, dynamic>? tokens = await fireStoreService.getDocumentDetails(tokenRef);
    if (tokens != null) {
      tokens.removeWhere((key, value) => key == regNo);
      List<dynamic> tokenValues = tokens.values.toList();
      print('Notification Tokens: $tokenValues');
      notificationService.sendNotification(tokenValues, title, message, additionalData);
    }
  }

  MediaType? getMediaType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return MediaType.image;
      case 'mp4':
      case 'mov':
        return MediaType.video;
      case 'mp3':
      case 'wav':
      case 'pdf':
      case 'doc':
      case 'docx':
        return MediaType.file;
      default:
        return null;
    }
  }

  Future<void> subscribeToUniversityChat() async {
    await FirebaseMessaging.instance.subscribeToTopic('UniversityChat');
  }

  Future<void> downloadAndOpenFile(String url, String filename) async {
    try {
      loadingDialog.showDefaultLoading('Getting File...');
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/ChatDownload/$filename';

      print('Temp File Path: $filePath');

      if (await File(filePath).exists()) {
        print('File already exists, opening...');
        loadingDialog.dismiss();
        setState(() {});

        String extension = path.extension(Uri.parse(url).path).toLowerCase();
        print('Extension: $extension');
        String mimeType = utils.getMimeType(extension);
        print('Mime Type: $mimeType');
        utils.openFile(filePath);
        return;
      }

      final dio = Dio();
      await dio.download(url, filePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          loadingDialog.showProgressLoading(received / total, 'Downloading...');
        }
      });
      loadingDialog.dismiss();
      setState(() {});

      String extension = path.extension(Uri.parse(url).path).toLowerCase();
      print('Extension: $extension');
      String mimeType = utils.getMimeType(extension);
      print('Mime Type: $mimeType');
      utils.openFile(filePath);
    } catch (e) {
      loadingDialog.dismiss();
      print('Error downloading or opening file: $e');
    }
  }

  @override
  void dispose() {
    print('University Chat Disposed');
    _focusNode.dispose();
    super.dispose();
  }
}
