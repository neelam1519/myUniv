import 'package:findany_flutter/busbooking/busbookinghome.dart';
import 'package:findany_flutter/groupchat/chatscreen.dart';
import 'package:findany_flutter/groupchat/groupchathome.dart';
import 'package:findany_flutter/materials/materialshome.dart';
import 'package:findany_flutter/universitynews/NewsList.dart';
import 'package:findany_flutter/useraccount/acedemicdetails_provider.dart';
import 'package:findany_flutter/provider/addnews_provider.dart';
import 'package:findany_flutter/provider/addnotification_provider.dart';
import 'package:findany_flutter/provider/auth_provider.dart';
import 'package:findany_flutter/busbooking/busbooking_home_provider.dart';
import 'package:findany_flutter/home_provider.dart';
import 'package:findany_flutter/Login/login_provider.dart';
import 'package:findany_flutter/navigation/map_provider.dart';
import 'package:findany_flutter/materials/materials_provider.dart';
import 'package:findany_flutter/universitynews/newsdetailsscreen_provider.dart';
import 'package:findany_flutter/universitynews/newslist_provider.dart';
import 'package:findany_flutter/provider/notificationhome_provider.dart';
import 'package:findany_flutter/provider/pdfscreen_provider.dart';
import 'package:findany_flutter/useraccount/personaldetails_provider.dart';
import 'package:findany_flutter/provider/qanda_provider.dart';
import 'package:findany_flutter/Other/review_provider.dart';
import 'package:findany_flutter/materials/showfiles_provider.dart';
import 'package:findany_flutter/useraccount/useraccount_provider.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/groupchat/groupchathome_provider.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'Firebase/storage.dart';
import 'Home.dart';
import 'auth_check_screen.dart';
import 'busbooking/fetch_buslist_provider.dart';
import 'firebase_options.dart';
import 'package:findany_flutter/services/sendnotification.dart';

import 'groupchat/chatscreen_provider.dart';
import 'materials/displaymaterials_drive_provider.dart';

late String routeToGo = '/';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  routeToGo = '/groupchat';
  NotificationService().showNotification(message);

}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProviderStart()),
        ChangeNotifierProvider(create: (_) => MaterialsProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => NewsListProvider()),
        ChangeNotifierProvider(create: (_) => BusBookingHomeProvider()),
        ChangeNotifierProvider(create: (_) => FetchBusListProvider()),
        ChangeNotifierProvider(create: (_) => AcademicDetailsProvider()),
        ChangeNotifierProvider(create: (_) => QAndAProvider()),
        ChangeNotifierProvider(create: (_) => PersonalDetailsProvider()),
        ChangeNotifierProvider(create: (_) => UserAccountProvider()),
        ChangeNotifierProvider(create: (_) => ShowFilesProvider()),
        ChangeNotifierProvider(create: (_) => PdfScreenProvider()),
        ChangeNotifierProvider(create: (_) => AddNewsProvider()),
        ChangeNotifierProvider(create: (_) => AddNotificationProvider()),
        ChangeNotifierProvider(create: (_) => NewsDetailsScreenProvider()),
        ChangeNotifierProvider(create: (_) => NotificationHomeProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => GroupChatHomeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PDFProvider())
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey, // Set the navigator key
        title: 'FindAny',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: AuthCheck(),
        builder: EasyLoading.init(),
        onGenerateRoute: (settings) {
          if (settings.name == '/chatPage') {
            final args = settings.arguments as Map<String, dynamic>;
            final roomId = args['roomId'];
            return MaterialPageRoute(
              builder: (context) => ChatScreen(room: roomId),
            );
          }
          return MaterialPageRoute(
            builder: (context) => AuthCheck(),
          );
        },
        routes: {
          '/auth': (context) => AuthCheck(),
          '/home': (context) => Home(),
          '/busBooking': (context) => BusBookingHome(),
          '/materials': (context) => MaterialsHome(),
          '/newsList': (context) => NewsListScreen(),
          '/groupchat': (context) => GroupChatHome(),
        },
      ),
    );
  }
}
