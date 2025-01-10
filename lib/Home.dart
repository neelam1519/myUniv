import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/busbooking/busbookinghome.dart';
import 'package:findany_flutter/home_provider.dart';
import 'package:findany_flutter/universitynews/NewsList.dart';
import 'package:findany_flutter/utils/grid_item.dart';
import 'package:findany_flutter/utils/test.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:findany_flutter/Other/notification.dart';
import 'package:findany_flutter/groupchat/groupchathome.dart';
import 'package:findany_flutter/materials/materialshome.dart';
import 'package:findany_flutter/navigation/navigationhome.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_drawer_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  late HomeProvider _homeProvider;
  Utils utils = Utils();
  FireStoreService firebaseFirestore = FireStoreService();

  @override
  void initState() {
    print('running init');

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeProvider = Provider.of<HomeProvider>(context, listen: false);
      _homeProvider.loadData(context);
      utils.updateToken();
      _homeProvider.requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.dosis(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.green.shade200,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationHome(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<HomeProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                if (provider.announcementText != null &&
                    provider.announcementText!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16.0),
                    child: Linkify(
                      text: provider.announcementText!,
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      linkStyle: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      onOpen: (link) async {
                        if (await canLaunch(link.url)) {
                          await launch(link.url);
                        } else {
                          throw 'Could not launch ${link.url}';
                        }
                      },
                    ),
                  ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    children: [
                      const GridItem(
                        imagePath: 'assets/images/groupchat.png',
                        title: 'Let\'s Talk',
                        destination: GroupChatHome(),
                      ),
                      GridItem(
                        imagePath: 'assets/images/materials.png',
                        title: 'Materials',
                        destination: MaterialsHome(),
                      ),
                      const GridItem(
                        imagePath: 'assets/images/navigation.png',
                        title: 'Navigation',
                        destination: MapScreen(),
                      ),
                      GridItem(
                        imagePath: 'assets/images/universitynews.jpeg',
                        title: 'University News',
                        destination: NewsListScreen(),
                      ),
                      GridItem(
                        imagePath: 'assets/images/busbooking.png',
                        title: 'Bus Booking',
                        destination: PDFViewerPage(pdfUrl: "https://drive.google.com/uc?export=download&id=1TB33HVqiX6JaUO1QsEEWgbM_51ffpsSp"),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
