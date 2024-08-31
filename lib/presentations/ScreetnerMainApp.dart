import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../pages/HomePage.dart';
import '../pages/LoginPage.dart';
import '../pages/NotificationPage.dart';
import '../pages/RecordPage.dart';

class ScreetnerMainApp extends StatelessWidget {
  ScreetnerMainApp({super.key});
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();


  Future<String?> _getAccessToken() async {
    final accessToken = await secureStorage
        .read(key: 'accessToken');
    return accessToken;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: FutureBuilder<String?>(
        future: _getAccessToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data != null) {
            return const ScreetnerHome();
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }}

class ScreetnerHome extends StatefulWidget {
  const ScreetnerHome({super.key});

  @override
  State<ScreetnerHome> createState() => _ScreetnerHomeState();
}

class _ScreetnerHomeState extends State<ScreetnerHome> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: <Widget>[
        HomePage(),
        RecordPage(),
        NotificationPage(),
      ][currentPageIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          if(index == 1) { // record Page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RecordPage()),
            );

            return;
          }
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.green,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home_outlined),
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.videocam_sharp),
            icon: Badge(child: Icon(Icons.videocam_sharp)),
            label: 'Record',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('2'),
              child: Icon(Icons.list),
            ),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
