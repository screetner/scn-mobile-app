import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tus_client_background_demo/services/interceptors/ExpiredTokenInterceptor.dart';

import '../pages/HomePage.dart';
import '../pages/InformationPage.dart';
import '../pages/LoginPage.dart';
import '../pages/NotificationPage.dart';
import '../pages/RecordPage.dart';
import '../services/models/SecureStorageCache.dart';

class ScreetnerMainApp extends StatelessWidget {
  ScreetnerMainApp({super.key});
  final FlutterSecureStorage secureStorage = SecureStorageCache();

  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      navigatorObservers: [routeObserver],
      home: FutureBuilder<bool>(
        future: ExpiredTokenInterceptor.isRefreshTokenExpired(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && !snapshot.data!) {
            return const ScreetnerHome();
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }
}

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
        const RecordPage(),
        const NotificationPage(),
        const InformationPage(),
      ][currentPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPageIndex,
        onTap: (int index) {
          if (index == 1) { // Navigate to Record Page
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
        type: BottomNavigationBarType.fixed, // Fixed type for consistent styling
        backgroundColor: Colors.blueGrey[900], // Background color
        selectedItemColor: Colors.white, // Color of the selected item
        unselectedItemColor: Colors.grey[400], // Color of the unselected items
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        items: [
          BottomNavigationBarItem(
            icon: _buildNavItemIcon(Icons.home, 0),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildNavItemIcon(Icons.videocam, 1),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: _buildNavItemIcon(Icons.list, 2),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: _buildNavItemIcon(Icons.info, 3),
            label: 'Information',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItemIcon(IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: currentPageIndex == index ? Colors.blueAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: currentPageIndex == index
            ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10, offset: Offset(0, 4))]
            : [],
      ),
      child: Icon(icon, size: 24, color: currentPageIndex == index ? Colors.white : Colors.grey[400]),
    );
  }
}
