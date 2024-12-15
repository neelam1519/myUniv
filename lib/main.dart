import 'package:findany_flutter/useraccount/acedemicdetails_provider.dart';
import 'package:findany_flutter/provider/addnews_provider.dart';
import 'package:findany_flutter/provider/addnotification_provider.dart';
import 'package:findany_flutter/provider/auth_provider.dart';
import 'package:findany_flutter/busbooking/busbooking_home_provider.dart';
import 'package:findany_flutter/groupchat/chatting_provider.dart';
import 'package:findany_flutter/groupchat/creategroupchat_provider.dart';
import 'package:findany_flutter/materials/display_materials_provider.dart';
import 'package:findany_flutter/groupchat/group_chat_provider.dart';
import 'package:findany_flutter/busbooking/history_provider.dart';
import 'package:findany_flutter/provider/home_provider.dart';
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
import 'package:findany_flutter/groupchat/universitychat_provider.dart';
import 'package:findany_flutter/useraccount/useraccount_provider.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'Firebase/storage.dart';
import 'Home.dart';
import 'Login/login.dart';
import 'auth_check_screen.dart';
import 'busbooking/fetch_buslist_provider.dart';
import 'firebase_options.dart';
import 'package:findany_flutter/services/sendnotification.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  NotificationService().showNotification(message);
}

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kIsWeb) {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: '87807759596-ijh25ipt7ig7bq78jl2lr70qjmhdu1m5.apps.googleusercontent.com',
    );
    try {
      await googleSignIn.signInSilently();
    } catch (error) {
      print('Error during Google Sign-In initialization: $error');
    }
  }

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/transperentlogo'),
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
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
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => FetchBuslistProvider()),
        ChangeNotifierProvider(create: (_) => CreateGroupChatProvider()),
        ChangeNotifierProvider(create: (_) => AcademicDetailsProvider()),
        ChangeNotifierProvider(create: (_) => QAndAProvider()),
        ChangeNotifierProvider(create: (_) => PersonalDetailsProvider()),
        ChangeNotifierProvider(create: (_) => UserAccountProvider()),
        ChangeNotifierProvider(create: (_) => ShowFilesProvider()),
        ChangeNotifierProvider(create: (_) => PdfScreenProvider()),
        ChangeNotifierProvider(create: (_) => AddNewsProvider()),
        ChangeNotifierProvider(create: (_) => AddNotificationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => GroupChatProvider()),
        ChangeNotifierProvider(create: (_) => BusBookedHistoryProvider()),
        ChangeNotifierProvider(create: (_) => NewsDetailsScreenProvider()),
        ChangeNotifierProvider(create: (_) => NotificationHomeProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => UniversityChatProvider()),
        ChangeNotifierProvider(create: (_) => DisplayMaterialsProvider(firebaseStorageHelper: FirebaseStorageHelper(),
            loadingDialog: LoadingDialog(),
            notificationService: NotificationService(),
            utils: Utils(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'FindAny',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: AuthCheck(),
        builder: EasyLoading.init(),
      ),
    );
  }
}
