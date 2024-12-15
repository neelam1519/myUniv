import 'package:findany_flutter/Home.dart';
import 'package:findany_flutter/useraccount/academicdetails.dart';
import 'package:findany_flutter/useraccount/personalDetails.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'useraccount_provider.dart';
import '../utils/utils.dart';
import 'package:provider/provider.dart';

class UserAccount extends StatefulWidget {
  const UserAccount({super.key});

  @override
  State<UserAccount> createState() => _UserAccountState();
}

class _UserAccountState extends State<UserAccount> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserAccountProvider>(context, listen: false).getUserDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
        return true;
      },
      child: Consumer<UserAccountProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('User Account'),
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: kToolbarHeight - 40),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () async {
                        print('Edit Profile');
                        if (await Utils().checkInternetConnection()) {
                          provider.pickFile();
                        } else {
                          Utils().showToastMessage('Check your internet connection');
                        }
                      },
                      child: Stack(
                        children: [
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: provider.imageUrl ?? '',
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    provider.name ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    provider.regNo ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Visibility(
                        visible: provider.showPersonalDetails,
                        child: ListTile(
                          title: const Text('Personal details', style: TextStyle(fontSize: 16)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PersonalDetails()),
                            );
                          },
                        ),
                      ),
                      Visibility(
                        visible: provider.showAcademicDetails,
                        child: ListTile(
                          title: const Text('Academic details', style: TextStyle(fontSize: 16)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AcademicDetails()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
