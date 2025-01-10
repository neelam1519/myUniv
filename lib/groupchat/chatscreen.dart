import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'chatscreen_provider.dart';

class ChatScreen extends StatelessWidget {
  final types.Room room;

  const ChatScreen({Key? key, required this.room}) : super(key: key);

  Future<void> _pickFile(BuildContext context, ChatProvider chatProvider) async {
    final ImagePicker _picker = ImagePicker();

    // Try picking an image or video
    final XFile? imageOrVideo =
    await _picker.pickImage(source: ImageSource.gallery);

    if (imageOrVideo != null) {
      try {
        final fileSize = await imageOrVideo.length();
        if (fileSize > 10 * 1024 * 1024) {
          print("File too large. Maximum allowed size is 10MB.");
          return;
        }

        // Create a partial file message for image/video
        final partialFile = types.PartialFile(
          mimeType: imageOrVideo.mimeType ?? 'application/octet-stream',
          name: imageOrVideo.name,
          size: fileSize,
          uri: imageOrVideo.path,
        );

        FirebaseChatCore.instance.sendMessage(partialFile, room.id);
      } catch (e) {
        print("Error picking file: $e");
      }
    } else {
      // Use FilePicker for other file types
      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        try {
          final pickedFile = result.files.first;

          if (pickedFile.size > 10 * 1024 * 1024) {
            print("File too large. Maximum allowed size is 10MB.");
            return;
          }

          // Create a partial file message for other files
          final partialFile = types.PartialFile(
            mimeType: pickedFile.extension != null
                ? 'application/${pickedFile.extension}'
                : 'application/octet-stream',
            name: pickedFile.name,
            size: pickedFile.size,
            uri: pickedFile.path!,
          );

          FirebaseChatCore.instance.sendMessage(partialFile, room.id);
        } catch (e) {
          print("Error picking file: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      ChatProvider()
        ..loadCurrentUser()
        ..loadMessages(room),
      child: Scaffold(
        body: SafeArea(
          child: Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return Column(
                children: [
                  Expanded(
                    child: Chat(
                      showUserNames: true,
                      showUserAvatars: true,
                      messages: chatProvider.messages,
                      onSendPressed: (types.PartialText message) {
                        chatProvider.handleSendPressed(message, room);
                      },
                      theme: DefaultChatTheme(
                        // Customize background and message styles
                        primaryColor: Colors.blueAccent,  // Custom primary color for sent messages
                        // receivedMessageBodyTextStyle: TextStyle(
                        //   color: Colors.black,  // Text color for received messages
                        //   backgroundColor: Colors.grey[200],  // Background color for received messages
                        // ),
                        // sentMessageBodyTextStyle: TextStyle(
                        //   color: Colors.white,  // Text color for sent messages
                        //   backgroundColor: Colors.blueAccent,  // Background color for sent messages
                        // ),
                        // Customize other properties as needed
                         //messageBorderRadius: 20,
                        // messageInsetsHorizontal: 12,
                        // messageInsetsVertical: 8,
                        // Customize the styling of user name, avatars, and more
                      ),
                      onMessageTap: (context, message) async {
                        if (message is types.FileMessage) {
                          try {
                            await OpenFile.open(message.uri);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Unable to open the file')),
                            );
                          }
                        }
                      },
                      user: chatProvider.user,
                      isAttachmentUploading: chatProvider.isAttachmentUploading,
                      onAttachmentPressed: () async {
                        await _pickFile(context, chatProvider);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
