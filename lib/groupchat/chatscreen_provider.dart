import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatProvider extends ChangeNotifier {

  List<types.Message> _messages = [];
  late types.User _user;

  bool _isAttachmentUploading = false;

  bool get isAttachmentUploading => _isAttachmentUploading;

  List<types.Message> get messages => _messages;
  types.User get user => _user;

  Future<void> loadCurrentUser() async {
    final firebaseUser = FirebaseChatCore.instance.firebaseUser;
    if (firebaseUser != null) {
      _user = types.User(
          id: firebaseUser.uid
      );
      notifyListeners();
    }
  }

  Future<void> loadMessages(types.Room room) async {
    FirebaseChatCore.instance.messages(room).listen((messages) {
      _messages = messages;
      notifyListeners();
    });
  }

  void handleSendPressed(types.PartialText message, types.Room room) async {
    try {
      FirebaseChatCore.instance.sendMessage(message, room.id);

      final newMessage = types.TextMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: DateTime.now().toString(),
        text: message.text,
        type: types.MessageType.text,
      );

      _messages.add(newMessage);
      notifyListeners();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  void sendFileMessage(types.FileMessage fileMessage, types.Room room) async {
    try {
      print("Attempting to send file message with ID: ${fileMessage.id}");
      print("File message details: ${fileMessage.toString()}");
      print("Room ID: ${room.id}");
      print("File path: ${fileMessage.uri}");
      _isAttachmentUploading = true;
      notifyListeners();

      // Send the file message

      // After sending the message, add it to the local message list
      print("File message sent successfully!");
      _messages.add(fileMessage);
      notifyListeners();
    } catch (e, stackTrace) {
      print("Error sending file message: $e");
      print("Stack trace: $stackTrace");
    } finally {
      _isAttachmentUploading = false;
      notifyListeners();
    }
  }



}
