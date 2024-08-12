import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/groupchat/groupchathome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/creategroupchat_provider.dart';

class CreateGroupChat extends StatefulWidget {
  const CreateGroupChat({super.key});

  @override
  State<CreateGroupChat> createState() => _CreateGroupChatState();
}

class _CreateGroupChatState extends State<CreateGroupChat> {
  late CreateGroupChatProvider createGroupChatProvider;

  @override
  void initState() {
    super.initState();
    createGroupChatProvider = Provider.of<CreateGroupChatProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Create Group Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Consumer<CreateGroupChatProvider>(
                  builder: (context, provider, child) {
                    return CachedNetworkImage(
                      imageUrl: provider.downloadUrl,
                      imageBuilder: (context, imageProvider) => CircleAvatar(
                        radius: 70,
                        backgroundImage: imageProvider,
                      ),
                      placeholder: (context, url) => const CircleAvatar(
                        radius: 70,
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey,
                        backgroundImage: AssetImage('assets/images/defaultimage.png'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20.0),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    String? imagePath = await createGroupChatProvider.pickFile();
                    if (imagePath != null) {
                      String? url = await createGroupChatProvider.uploadImageAndStoreUrl(imagePath);
                      if (url != null) {
                        createGroupChatProvider.downloadUrl = url;
                      }
                    }
                  },
                  child: const Text('Edit Profile'),
                ),
              ),
              const Text(
                'Group Name:',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10.0),
              TextField(
                controller: createGroupChatProvider.groupNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter group name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Who can message:',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10.0),
              Consumer<CreateGroupChatProvider>(
                builder: (context, provider, child) {
                  return DropdownButton<String>(
                    value: provider.selectedMessagePermission,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        provider.selectedMessagePermission = newValue;
                      }
                    },
                    items: <String>['Admins', 'Anyone'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Reason of Group:',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10.0),
              TextField(
                controller: createGroupChatProvider.groupReasonController,
                decoration: const InputDecoration(
                  hintText: 'Enter reason of group',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20.0),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    createGroupChatProvider.loadingDialog.showDefaultLoading('Creating Group');
                    int? groupNumber =
                        await createGroupChatProvider.realTimeDatabase.incrementValue('GroupChats/NoOfGroups');
                    String groupName = createGroupChatProvider.groupNameController.text;
                    String whoCanMessage = createGroupChatProvider.selectedMessagePermission;
                    String reasonOfGroup = createGroupChatProvider.groupReasonController.text;

                    DocumentReference groupRef = FirebaseFirestore.instance.doc('/GroupChats/$groupNumber');

                    Map<String, dynamic> data = {
                      'GroupName': groupName,
                      'GroupNumber': groupNumber,
                      'WhoCanMessage': whoCanMessage,
                      'ReasonOfGroup': reasonOfGroup,
                      'ProfileUrl': createGroupChatProvider.downloadUrl
                    };

                    await createGroupChatProvider.fireStoreService.uploadMapDataToFirestore(data, groupRef);

                    DocumentReference userRef = FirebaseFirestore.instance
                        .doc('UserDetails/${createGroupChatProvider.utils.getCurrentUserUID()}/Other/GroupChat');

                    await createGroupChatProvider.fireStoreService
                        .uploadMapDataToFirestore({'$groupNumber': groupRef}, userRef);

                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GroupChatHome()));
                    createGroupChatProvider.loadingDialog.dismiss();
                  },
                  child: const Text('Create Group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    createGroupChatProvider.dispose();
    super.dispose();
  }
}
