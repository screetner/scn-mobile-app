import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tus_client_background_demo/model/DirectoryUploadManager.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          Card(
            child: ListTile(
              leading: Icon(Icons.notifications_sharp),
              title: Text('NotificationPage.dart 1'),
              subtitle: Text('This is a notification'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.notifications_sharp),
              title: Text('NotificationPage.dart 2'),
              subtitle: Text('This is a notification'),
            ),
          ),
          ElevatedButton(
            onPressed: () => _pickDirectory(),
            child: Text('Press Me'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Background color
              foregroundColor: Colors.white, // Text color
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0), // Padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0), // Rounded corners
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _pickDirectory() async {
    final chosenDir = '/data/data/com.example.tus_client_background_demo/app_flutter/records';

    print("uploading directory: ${chosenDir}");
    print("try create directory: ${new Directory(chosenDir)}");

    await DirectoryUploadManager().uploadDirectory(uploadDirectory: Directory(chosenDir));
  }
}