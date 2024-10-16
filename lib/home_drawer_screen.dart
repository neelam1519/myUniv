import 'package:cached_network_image/cached_network_image.dart';
import 'package:findany_flutter/provider/home_provider.dart';
import 'package:findany_flutter/useraccount/useraccount.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Other/QandA.dart';
import 'Other/review.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    UserAccountsDrawerHeader(
                      accountName: Text(provider.name!),
                      accountEmail: Text(provider.email!),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                      ),
                      currentAccountPicture: CircleAvatar(
                        backgroundImage: provider.imageUrl != null &&
                                provider.imageUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(provider.imageUrl!)
                                as ImageProvider<Object>?
                            : const AssetImage(
                                'assets/images/defaultimage.png'),
                        backgroundColor: Colors.white,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Profile'),
                      onTap: () async {
                        if (await provider.utils.checkInternetConnection()) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const UserAccount()),
                          );
                        } else {
                          provider.utils.showToastMessage(
                            "Connect to the internet",
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.reviews),
                      title: const Text('Reviews/Suggestions'),
                      onTap: () async {
                        if (await provider.utils.checkInternetConnection()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Review()),
                          );
                        } else {
                          provider.utils
                              .showToastMessage("Connect to the internet");
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.question_answer),
                      title: const Text('Q & A'),
                      onTap: () async {
                        if (await provider.utils.checkInternetConnection()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const QuestionAndAnswer()),
                          );
                        } else {
                          provider.utils.showToastMessage(
                            "Connect to the internet",
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.exit_to_app),
                      title: const Text('Sign Out'),
                      onTap: () async {
                        if (await provider.utils.checkInternetConnection()) {
                          await provider.utils.signOut(context);
                        } else {
                          provider.utils.showToastMessage(
                              'Check your internet connections');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
