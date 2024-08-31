import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tus_client_background_demo/providers/DirectoryUploadManager.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildNotificationCard(
            context,
            'NotificationPage.dart 1',
            'This is a notification',
          ),
          _buildNotificationCard(
            context,
            'NotificationPage.dart 2',
            'This is a notification',
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _pickDirectory(),
            child: const Text('Upload All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent, // Background color
              foregroundColor: Colors.white, // Text color
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0), // Padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
              ),
              elevation: 4,
              shadowColor: Colors.blueAccent.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Icon(Icons.notifications_sharp, color: Colors.blueAccent),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Future<void> _pickDirectory() async {
    final chosenDir = '/data/data/com.example.tus_client_background_demo/app_flutter/records';

    print("Uploading directory: ${chosenDir}");
    print("Try creating directory: ${new Directory(chosenDir)}");

    await DirectoryUploadManager().uploadDirectory(uploadDirectory: Directory(chosenDir));
  }
}
