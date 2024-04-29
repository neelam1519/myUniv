import 'dart:async';
import 'dart:collection';
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
import 'package:flutter/widgets.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UniversityChat extends StatefulWidget {
  @override
  _UniversityChatState createState() => _UniversityChatState();
}

class _UniversityChatState extends State<UniversityChat> {
  SharedPreferences sharedPreferences = SharedPreferences();
  FireStoreService fireStoreService = FireStoreService();
  RealTimeDatabase realTimeDatabase = new RealTimeDatabase();
  LoadingDialog loadingDialog = new LoadingDialog();
  Utils utils = new Utils();

  final FocusNode _focusNode = FocusNode();


  FirebaseStorage storage = FirebaseStorage.instance;

  late Stream<QuerySnapshot> chattingStream;
  late Stream<QuerySnapshot> typingStream;
  late StreamGroup<QuerySnapshot<Object?>> mergedStream;

  Timer? _typingTimer;

  late ChatUser user = ChatUser(id: '', firstName: '', profileImage: '');
  late List<ChatUser> typingUsers = [];
  List<ChatMessage> messages=[];
  List<ChatMedia> chatMedia = [];
  List<String?> filePaths = [];
  List<File> selectedFiles = [];
  String name = '', email = '', regNo = '', profileUrl = '';

  String hintText = 'Type your message';


  late List<QuerySnapshot> snapshots = [];

  @override
  void initState() {
    super.initState();
    loadingDialog.showDefaultLoading('Getting Messages...');
    subscribeToUniversityChat();

    chattingStream = FirebaseFirestore.instance.collection('Chatting').orderBy('createdAt', descending: true).snapshots();
    typingStream = FirebaseFirestore.instance.collection('TypingDetails').snapshots();
    //mergedStream = StreamGroup<QuerySnapshot<Object?>>.broadcast([chattingStream, typingStream]);
    loadingDialog.showDefaultLoading('Getting Messages');
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

  Widget build(BuildContext context) {
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
                return StreamBuilder<QuerySnapshot>(
                  stream: typingStream,
                  builder: (context, typingSnapshot) {
                    // Handle error states
                    if (chattingSnapshot.hasError) {
                      return Text('Error: ${chattingSnapshot.error}');
                    }
                    if (typingSnapshot.hasError) {
                      return Text('Error: ${typingSnapshot.error}');
                    }

                    if (chattingSnapshot.hasData && typingSnapshot.hasData) {
                      snapshots = [chattingSnapshot.data!, typingSnapshot.data!];
                      final data1 = chattingSnapshot.data!.size;
                      final data2 = typingSnapshot.data!.size;
                      print('Received Data from Chatting: $data1');
                      print('Received Data from Typing: $data2');
                      loadingDialog.dismiss();
                    }

                    if (chattingSnapshot.hasData) {
                      messages = chattingSnapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        String dateTimeString = data['createdAt'];
                        DateTime dateTime = DateTime.parse(dateTimeString);

                        print('getting chat');
                        Map<String, dynamic> mapData = data['user'];
                        ChatUser user = ChatUser.fromJson(mapData);

                        List<ChatMedia> listMedia = [];
                        List<dynamic>? mediaData = data['medias'];
                        if (mediaData != null && mediaData.isNotEmpty) {
                          for (Map<String, dynamic> mapMedia in mediaData) {
                            listMedia.add(ChatMedia.fromJson(mapMedia));
                          }
                          print('MapMedia: ${listMedia}');
                        }
                        return ChatMessage(
                          text: data['text'],
                          user: user,
                          medias: listMedia,
                          createdAt: dateTime,
                        );
                      }).toList();
                    }

                    if (typingSnapshot.hasData) {
                      typingUsers = typingSnapshot.data!.docs
                          .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return ChatUser(
                          id: data['id'],
                          firstName: data['Name'],
                        );
                      }).where((user) => user.id != user.id) // Exclude current user
                          .toList();
                    }
                    print('Messages: ${messages}');
                    print('Typing Users: ${typingUsers}');

                    // Return your widget here
                    return buildDashChat(messages, typingUsers);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDashChat(List<ChatMessage> messages, List<ChatUser> typingUsers) {
    return Column(
      children: [
        Expanded(
          child: DashChat(
            currentUser: user,
            onSend: (ChatMessage m) async {
              try {
                if (selectedFiles.isNotEmpty) {
                  loadingDialog.showDefaultLoading('Upload Files to chat');
                  loadingDialog.showProgressLoading(0, 'Files are uploading');

                  for (File file in selectedFiles) {
                    print('Uploading Files...');
                    String filepath = file.path;
                    String filename = path.basename(filepath);
                    String extension = utils.getFileExtension(File(filepath));

                    Reference ref = storage.ref().child('ChatMedia').child('${utils.getCurrentUserUID()}').child('$filename');
                    final UploadTask uploadTask = ref.putFile(File(filepath));

                    // Track the upload progress using stream
                    final StreamSubscription<TaskSnapshot> streamSubscription = uploadTask.snapshotEvents.listen((event) {
                      double progress = event.bytesTransferred / event.totalBytes;
                      loadingDialog.showProgressLoading(progress, 'Uploading file $filename');
                    });

                    await uploadTask.whenComplete(() {
                      streamSubscription.cancel(); // Cancel the subscription
                    });

                    final String downloadUrl = await ref.getDownloadURL();

                    MediaType? mediaType = getMediaType(extension);
                    chatMedia.add(ChatMedia(url: downloadUrl, fileName: filename, type: mediaType!));
                  }

                  loadingDialog.dismiss();
                  utils.showToastMessage('Files uploaded', context);
                }

                ChatMessage chatMessage = ChatMessage(user: user, createdAt: DateTime.now(), text: m.text, medias: List.from(chatMedia));
                DocumentReference documentReference = FirebaseFirestore.instance.doc('Chatting/${Timestamp.now().microsecondsSinceEpoch.toString()}');
                await fireStoreService.uploadMapDataToFirestore(chatMessage.toJson(), documentReference);
                setState(() {
                  selectedFiles.clear();
                  chatMedia.clear();
                });
                utils.showToastMessage('Message sent', context);
              } catch (e) {
                loadingDialog.dismiss(); // Dismiss the loading dialog in case of an error
                print('Error sending message: $e');
                utils.showToastMessage('Error sending message', context);
              }
            },
            
            messages: messages,
            inputOptions: InputOptions(
              alwaysShowSend: true,
              inputDecoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                hintText: hintText,
                suffixIcon: IconButton(
                  icon: Icon(Icons.attach_file), // Choose an appropriate icon
                  onPressed: () {
                    pickFile();
                  },
                ),
              ),
              onTextChange: (String value) async {
                DocumentReference documentReference =
                FirebaseFirestore.instance.doc('TypingDetails/${user.id}');
                _typingTimer?.cancel();
                _typingTimer = Timer(Duration(seconds: 1), () {
                  print('User stopped typing');
                  fireStoreService.deleteDocument(documentReference);
                });
                Map<String, String> data = {'id': user.id, 'Name': user.firstName!};
                fireStoreService.uploadMapDataToFirestore(data, documentReference);
              },
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
                // Handle media tap
                print('Media tapped: ${media.url}');
              },
            ),

            typingUsers: typingUsers,
          ),
        ),
        _buildSelectedFilesWidget(),
      ],
    );
  }

  Widget _buildSelectedFilesWidget() {
    hintText='write about the files to send in chat';
    return selectedFiles.isNotEmpty
        ? Container(
      height: 120, // Increased height to accommodate filename
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: selectedFiles.length,
        itemBuilder: (context, index) {
          String fileName = selectedFiles[index].path.split('/').last;
          String filePath = selectedFiles[index].path;

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end, // Align items to the bottom
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
                SizedBox(height: 8), // Increased height to add more space between media and filename
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
        : SizedBox.shrink(); // Return an empty SizedBox if selectedFiles is empty
  }

  Widget buildMediaMessage(List<ChatMedia> medias) {
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
                  SizedBox(height: 4), // Add some space between image and filename
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
                  SizedBox(height: 4), // Add some space between video and filename
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
                  SizedBox(height: 4), // Add some space between file icon and filename
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
          return Container(); // Handle other media types if needed
        }
      }).toList(),
    );
  }

  String extractFileName(String url) {
    String decodedUrl = Uri.decodeFull(url); // Decode the URL
    RegExp regExp = RegExp(r'[^\/]+(?=\?)'); // Matches text between the last '/' and '?'
    Match? match = regExp.firstMatch(decodedUrl);
    return match?.group(0) ?? ''; // Return matched text or empty string if no match
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

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['jpg', 'jpeg', 'png','pdf','docx'],
      );
      if (result != null) {
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
    name = (await sharedPreferences.getSecurePrefsValue('Name'))!;
    email = (await sharedPreferences.getSecurePrefsValue('Email'))!;
    regNo = (await sharedPreferences.getSecurePrefsValue('Registration Number'))!;
    profileUrl = (await sharedPreferences.getSecurePrefsValue('ProfileImageURL'))!; // Retrieve profile URL
    print('Details $name  $email  $regNo  $profileUrl');
  }

  Future<void> sendNotification(String title,String message) async {
    Map<String,dynamic> additionalData = {'source':'UniversityChat'};
    DocumentReference tokenRef = FirebaseFirestore.instance.doc('/Tokens/Tokens');
    NotificationService notificationService = new NotificationService();
    Map<String, dynamic>? tokens = await fireStoreService.getDocumentDetails(tokenRef);
    if(tokens != null) {
      tokens.removeWhere((key, value) => key == regNo);
      List<dynamic> tokenValues = tokens.values.toList();
      print('Chat Tokens: $tokenValues');
      notificationService.sendNotification(tokenValues,title,message,additionalData);
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
        loadingDialog.showDefaultLoading('Getting File...'); // Show progress indicator
        final dir = await getTemporaryDirectory(); // Get temporary directory
        final filePath = '${dir.path}/ChatDownload/$filename'; // Create file path

        print('Temp File Path: ${filePath}');

        // Check if the file already exists
        if (await File(filePath).exists()) {
          print('File already exists, opening...');
          loadingDialog.dismiss();
          setState(() {});

          String extension = path.extension(Uri.parse(url).path).toLowerCase();
          print('Extension: $extension');
          String mimeType = utils.getMimeType(extension);
          print('Mime Type: $mimeType');
          await OpenFile.open(
            filePath,
            type: mimeType,
          );
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
        await OpenFile.open(
          filePath,
          type: mimeType,
        );
      } catch (e) {
        loadingDialog.dismiss(); // Dismiss progress indicator in case of error
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


