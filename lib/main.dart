import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tus_client_background_demo/providers/ImageLocationRecordController.dart';
import 'package:tus_client_background_demo/types/ImmutableVideoRecordManagerContext.dart';
import 'package:tus_client_background_demo/providers/DirectoryUploadManager.dart';

import 'types/ImmutableUploadManagerContext.dart';
import 'providers/VideoMetadataProvider.dart';
import 'presentations/ScreetnerMainApp.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  UploadContext fumc = await getEnvUploadContext();
  RecordContext vrmc = await getEnvRecordContext();

  await requestStoragePermission();
  await requestCameraPermission();
  await requestLocationPermission();
  await DirectoryUploadManager().initialize(fumc);
  await VideoMetadataProvider().initialize(vrmc);
  await ImageLocationRecordController.initialize(vrmc);
  runApp(ScreetnerMainApp());
}

Future<UploadContext> getEnvUploadContext() async {
  return new UploadContext(
    tusdServerUrl: Uri.parse(dotenv.env['TUSD_SERVER_URL']!),
    tusStoreDirectory: Directory(dotenv.env['TUS_STORE_DIRECTORY'] ?? path.join((await getApplicationSupportDirectory()).path, 'tusStore')),
    notificationChannelKey: dotenv.env['NOTIFICATION_CHANNEL_KEY'] ?? 'scn-mobile-app-progress-notification',
    notificationChannelGroupKey: dotenv.env['NOTIFICATION_CHANNEL_GROUP_KEY'] ?? 'scn-mobile-app',
    notificationChannelName: dotenv.env['NOTIFICATION_CHANNEL_NAME'],
    notificationChannelGroupName: dotenv.env['NOTIFICATION_CHANNEL_GROUP_NAME'],
    notificationChannelDescription: dotenv.env['NOTIFICATION_CHANNEL_DESCRIPTION'],
    notificationSoundSource: dotenv.env['NOTIFICATION_SOUND_SOURCE'],
    notificationDefaultColor: dotenv.env['NOTIFICATION_DEFAULT_COLOR'] != null
      ? Color(int.parse(dotenv.env['NOTIFICATION_DEFAULT_COLOR']!, radix: 16))
          : null,
    notificationVibrationPattern: dotenv.env['NOTIFICATION_VIBRATION_PATTERN'] != null
      ? Int64List.fromList(dotenv.env['NOTIFICATION_VIBRATION_PATTERN']!.split(',').map(int.parse).toList())
          : null,
    tusdToken: '',
  );
}


Future<RecordContext> getEnvRecordContext() async {
  return new RecordContext(
      recordDirectory: new Directory(path.join((await getApplicationDocumentsDirectory()).path, 'records')),
      recordIntervalMilliseconds: 1000,
  );
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

Future<void> requestStoragePermission() async {
  final status = await Permission.storage.request();
  if (status.isGranted) {
    print('Storage permission granted');
  } else {
    print('Storage permission not granted');
  }
}

Future<void> requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (status.isGranted) {
    print('Camera permission granted');
  } else {
    print('Camera permission not granted');
  }
}

Future<void> requestLocationPermission() async {
  final status = await Permission.location.request();
  if (status.isGranted) {
    print('Location permission granted');
  } else {
    print('Location permission not granted');
  }
}