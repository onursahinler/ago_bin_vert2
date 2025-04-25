import 'package:flutter/material.dart';
import 'login_page.dart';
import 'trash_bins_list_page.dart';
import 'notifications_page.dart';
// import 'trash_bins_map_page.dart';
import 'profile_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        // '/map_view': (context) => TrashBinsMapPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}