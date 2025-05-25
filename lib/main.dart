import 'package:ago_bin_vert/map_view_of_trash_bins_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'trash_bins_list_page.dart';
import 'notifications_page.dart';
// import 'trash_bins_map_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'bluetooth_log_page.dart';
import 'services/auth_service.dart';
import 'services/bluetooth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with manual options from google-services.json
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDnz20Cx3S-YoylFTOr6znONXDrorUhMHw",
      appId: "1:291035837946:android:7f21f526f2c4c4decfe043",
      messagingSenderId: "291035837946", 
      projectId: "ago-bin-vert",
      storageBucket: "ago-bin-vert.firebasestorage.app",
    ),
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BluetoothManager()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AGO BinVert',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => LoginPage(),
          '/trash_bins': (context) => TrashBinsListPage(),
          '/notifications': (context) => NotificationsPage(),
          '/map_view': (context) => MapViewPage(),
          '/profile': (context) => ProfilePage(),
          '/settings': (context) => SettingsPage(),
          '/bluetooth_logs': (context) => BluetoothLogPage(),
        },
      ),
    );
  }
}