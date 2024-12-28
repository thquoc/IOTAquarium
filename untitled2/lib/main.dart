import 'package:flutter/material.dart';
import 'views/home_page.dart';
import 'views/chart_page.dart';
import 'views/device_control.dart';
import 'views/detail_announcement.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  // Danh sách các trang
  final List<Widget> _pages = [
    HomePage(),
    DeviceController(),
    ChartPage(),
    DetailAnnouncement(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.pink[200],
        scaffoldBackgroundColor: Colors.blue[100],
      ),
      home: Scaffold(
        body: _pages[_currentIndex],  // Hiển thị trang hiện tại
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: Colors.pink[200],
          unselectedItemColor: Colors.pink[300],
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.devices),
              label: 'Device Control',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'Chart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Detail',
            ),
          ],
        ),
      ),
    );
  }
}
