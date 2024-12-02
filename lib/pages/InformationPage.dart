import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../component/customButton.dart';
import '../pages/LoginPage.dart';
import '../services/models/SecureStorageCache.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({Key? key}) : super(key: key);

  @override
  _InformationPageState createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  final FlutterSecureStorage secureStorage = SecureStorageCache();
  late final String username;
  late final String orgName;
  late final String role;
  bool isLoading = true;

  final List<Map<String, dynamic>> menuItems = [
    {
      'icon': Icons.person_outline,
      'title': 'Edit Profile',
      'subtitle': 'Change your account information'
    },
    {
      'icon': Icons.lock_outline,
      'title': 'Privacy',
      'subtitle': 'Control your privacy settings'
    },
    {
      'icon': Icons.help_outline,
      'title': 'Help & Support',
      'subtitle': 'Get help or contact us'
    },
    {
      'icon': Icons.info_outline,
      'title': 'About',
      'subtitle': 'Learn more about the app'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storedUsername =
        await secureStorage.read(key: 'username') ?? 'John Doe';
    final storedOrgName =
        await secureStorage.read(key: 'orgName') ?? 'Organization';
    final storedRole = await secureStorage.read(key: 'role') ?? 'Role';

    setState(() {
      username = storedUsername;
      orgName = storedOrgName;
      role = storedRole;
      isLoading = false; // Set loading to false when data is loaded
    });
  }

  Future<void> _logout() async {
    await secureStorage.deleteAll();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    expandedHeight: 150.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [Colors.blue, Colors.teal],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person,
                                    size: 60, color: Colors.blue),
                              ),
                              const SizedBox(width: 16),
                              // Space between avatar and information
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    username.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    orgName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    role,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ...menuItems
                        .map((item) => _buildMenuItem(context, item))
                        .toList(),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Log Out',
                      icon: Icons.logout,
                      onPressed: _logout,
                      backgroundColor: Colors.redAccent,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMenuItem(BuildContext context, Map<String, dynamic> item) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Handle menu item tap
        },
        splashColor: Colors.blue.withOpacity(0.1),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item['icon'], color: Colors.blue),
          ),
          title: Text(
            item['title'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            item['subtitle'],
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
