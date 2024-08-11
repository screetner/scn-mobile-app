import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:tus_client_background_demo/context/ImmutableDirectoryUploadInput.dart';
import 'package:tus_client_background_demo/model/DirectoryUploadClient.dart';
import 'package:tus_client_background_demo/model/NotificationManager.dart';
import 'package:tus_client_dart/tus_client_dart.dart';
import 'package:workmanager/workmanager.dart';

import '../context/ImmutableUploadManagerContext.dart';
import 'DirectoryUploadStore.dart';

class DirectoryUploadManager {
  bool _isInitialized = false;

  late final Uri _tusdServerUrl;
  late final Directory _tusStoreDirectory;
  late final UploadContext _context;

  DirectoryUploadManager._privateConstructor();

  static final DirectoryUploadManager _instance = DirectoryUploadManager._privateConstructor();

  factory DirectoryUploadManager() {
    return _instance;
  }

  // NOTE: THIS CLASS MUST BE INITIALIZED AFTER NOTIFICATION MANAGER
  Future<bool> initialize(UploadContext context) async {
    if (_isInitialized) {
      return false;
    }

    _context = context;
    _tusdServerUrl = context.tusdServerUrl;
    _tusStoreDirectory = context.tusStoreDirectory;
    print("INITIALIZING FILE UPLOAD MANAGER");
    print("_tusdServerUrl: $_tusdServerUrl");
    print("_tusStoreDirectory: $_tusStoreDirectory");

    bool notificationsInitialized = await NotificationManager().initialize(context);
    print("notificationsInitialized: " + notificationsInitialized.toString());
    await _initializeWorkmanager();

    _isInitialized = notificationsInitialized;
    return notificationsInitialized;
  }

  Future<void> uploadDirectory({required Directory uploadDirectory, int? chunkSize}) async {
    Map<String, dynamic> inputMap = getWorkmanagerContext(uploadDirectory: uploadDirectory, chunkSize: chunkSize).getAsMap();
    // inputData['chunk_size'] = (512 * 1024);

    print("EXECUTE UPLOAD DIRECTORY ON WORK MANAGER");
    // Workmanager().registerOneOffTask(getTaskUniqueName(uploadDirectoryPath),'_',
    //     constraints: Constraints(networkType: NetworkType.connected),
    //     inputData: contextMap,
    //     existingWorkPolicy: ExistingWorkPolicy.replace);
    // // TODO: change ExistingWorkPolicy from replace to keep

    await foreGroundWorkManagerForDebugging(inputMap);

    print("WORK MANAGER CALLED");

  }

  // Future<void> cancelUpload(String filePath) async {
  //   Workmanager().cancelByUniqueName(getTaskUniqueName(filePath));
  // }

  Future<void> pauseUpload(String filePath) async {
    // TODO: pause each tus client
    Workmanager().cancelByUniqueName(getTaskUniqueName(filePath));
    NotificationManager().removeNotificationIdFor(filePath);
  }

  Future<void> _initializeWorkmanager() async {
    print("INITIALIZING WORK MANAGER");
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
  }

  String getTaskUniqueName(String str) {
    return str.replaceAll(RegExp(r"\W+"), '.');
  }

  DirectoryUploadInput getWorkmanagerContext({required Directory uploadDirectory, int? chunkSize}) {
    return new DirectoryUploadInput(
      uploadDirectory: uploadDirectory,
      chunkSize: chunkSize,
      tusdServerUrl: _context.tusdServerUrl,
      tusStoreDirectory: _context.tusStoreDirectory,
      notificationChannelKey: _context.notificationChannelKey,
      notificationChannelGroupKey: _context.notificationChannelGroupKey,
      notificationChannelName: _context.notificationChannelName,
      notificationChannelGroupName: _context.notificationChannelGroupName,
      notificationChannelDescription: _context.notificationChannelDescription,
      notificationSoundSource: _context.notificationSoundSource,
      notificationDefaultColor: _context.notificationDefaultColor,
      notificationVibrationPattern: _context.notificationVibrationPattern
    );
  }

  UploadContext getContext() {
    return _context;
  }
}

dynamic Function(double, Duration) throttle(dynamic Function(double, Duration) callback, Duration duration) {
  DateTime lastExecution = DateTime.fromMillisecondsSinceEpoch(0);
  return (double progress, Duration estimate) {
    var now = DateTime.now();
    if (now.difference(lastExecution) >= duration) {
      lastExecution = now;
      callback(progress, estimate);
    }
  };
}

@pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("PRINT FROM WORK MANAGER");
    final DirectoryUploadInput context = DirectoryUploadInput.getAsObject(inputData!);
    final NotificationManager nm = NotificationManager();

    final tusStoreDirectory = context.tusStoreDirectory;

    final uploadDirectory = context.uploadDirectory;
    final uploadDirectoryPath = uploadDirectory.path;
    final chunkSize = context.chunkSize ?? 512 * 1024;

    if (!tusStoreDirectory.existsSync()) {
      tusStoreDirectory.createSync(recursive: true);
    }

    final client = DirectoryUploadClient(
      uploadDirectory,
      store: DirectoryUploadFileStore(tusStoreDirectory),
      maxChunkSize: chunkSize,
    );

    print("Starting upload");
    await client.upload(
      onFileUploadStart: (client,estimate) => nm.updateProgressBarFor(uploadDirectoryPath, 0, context),

      onDirectoryUploadProgress: throttle((totalProgress, _) {
        nm.updateProgressBarFor(uploadDirectoryPath, totalProgress, context);
      }, const Duration(seconds: 1)), // Ensure that the progressBar won't be called more than once per second.

      onFileUploadComplete: () async {
        print("Completed!");
        nm.removeNotificationIdFor(uploadDirectoryPath);
      },

      uri: context.tusdServerUrl,
      metadata: {
        'testMetaData': 'testMetaData',
        'testMetaData2': 'testMetaData2',
      },
      headers: {
        'testHeaders': 'testHeaders',
        'testHeaders2': 'testHeaders2',
      },
      measureUploadSpeed: false,
    );
    return Future.value(true);
  });
}

foreGroundWorkManagerForDebugging(inputData) async {
  print("PRINT FROM WORK MANAGER");
  final DirectoryUploadInput context = DirectoryUploadInput.getAsObject(inputData!);
  final NotificationManager nm = NotificationManager();

  final tusStoreDirectory = context.tusStoreDirectory;

  final uploadDirectoryPath = inputData['upload_directory_path']!;
  final uploadDirectory = new Directory(uploadDirectoryPath);
  final chunkSize = inputData['chunk_size'] ?? (512 * 1024); // 512 kB by default

  if (!tusStoreDirectory.existsSync()) {
    tusStoreDirectory.createSync(recursive: true);
  }

  final client = DirectoryUploadClient(
    uploadDirectory,
    store: DirectoryUploadFileStore(tusStoreDirectory),
    maxChunkSize: chunkSize,
  );

  client.setUploadData(context.tusdServerUrl, null, null);

  print("Starting upload");
  await client.upload(
    onFileUploadStart: (client,estimate) => nm.updateProgressBarFor(uploadDirectoryPath, 0, context),

    onDirectoryUploadProgress: throttle((totalProgress, _) {
      nm.updateProgressBarFor(uploadDirectoryPath, totalProgress, context);
    }, const Duration(seconds: 1)), // Ensure that the progressBar won't be called more than once per second.

    onFileUploadComplete: () async {
      print("Completed!");
      nm.removeNotificationIdFor(uploadDirectoryPath);
    },

    uri: context.tusdServerUrl,
    metadata: {
      'testMetaData': 'testMetaData',
      'testMetaData2': 'testMetaData2',
    },
    headers: {
      'testHeaders': 'testHeaders',
      'testHeaders2': 'testHeaders2',
    },
    measureUploadSpeed: false,
  );
  return Future.value(true);
}