import 'dart:async';
import 'dart:io';

import 'package:tus_client_background_demo/types/ImmutableDirectoryUploadInput.dart';
import 'package:tus_client_background_demo/services/DirectoryUploadClient.dart';
import 'package:tus_client_background_demo/providers/NotificationManager.dart';
import 'package:workmanager/workmanager.dart';

import '../types/ImmutableUploadManagerContext.dart';

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
    Map<String, dynamic> inputData = getWorkmanagerContext(uploadDirectory: uploadDirectory, chunkSize: chunkSize).toJson();

    print("EXECUTE UPLOAD DIRECTORY ON WORK MANAGER: " + getTaskUniqueName(uploadDirectory.path));
    Workmanager().registerOneOffTask(getTaskUniqueName(uploadDirectory.path),'_',
        constraints: Constraints(networkType: NetworkType.connected),
        inputData: inputData,
        existingWorkPolicy: ExistingWorkPolicy.replace);
    // TODO: change ExistingWorkPolicy from replace to keep

    print("WORK MANAGER CALLED");
  }

  Future<void> cancelUpload(String filePath) async {
    // TODO: cancel the client gracefully
    Workmanager().cancelByUniqueName(getTaskUniqueName(filePath));
  }

  Future<void> pauseUpload(String filePath) async {
    // TODO: pause each tus gracefully
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
    try {
      print("ENTERS, WORKMANAGER");
      final DirectoryUploadInput uploadInput = DirectoryUploadInput.toObject(
          inputData!);
      final UploadContext uploadContext = UploadContext.toObject(inputData);

      final NotificationManager nm = await NotificationManager.createInstance(uploadContext);

      final storeDirectory = uploadInput.tusStoreDirectory;

      final uploadDirectory = uploadInput.uploadDirectory;
      final uploadDirectoryPath = uploadDirectory.path;
      final nmFingerprint = uploadDirectoryPath;
      final chunkSize = uploadInput.chunkSize ??
          (512 * 1024); // 512 kB by default

      if (!storeDirectory.existsSync()) {
        storeDirectory.createSync(recursive: true);
      }

      final client = DirectoryUploadClient(
        uploadDirectory,
        storeDirectory: storeDirectory,
        maxChunkSize: chunkSize,
      );

      final uploadProgress = client.getUploadProgressPercentage;

      await client.upload(
        onFileUploadStart: (client, estimate) =>
            nm.updateProgressBarFor(nmFingerprint, uploadProgress()),

        onFileUploadProgress: throttle((progressPercentage, estimate) {
          nm.updateProgressBarFor(nmFingerprint, uploadProgress());
        }, const Duration(seconds: 1)),
        // Ensure that the progressBar won't be called more than once per second.

        onFileUploadComplete: () {
          nm.updateProgressBarFor(nmFingerprint, uploadProgress());
          print("UPLOAD FINISHED");
        },

        tusServerUri: uploadInput.tusdServerUrl,
        genericMetadata: {
          'testMetaData': 'testMetaData',
          'testMetaData2': 'testMetaData2',
        },
        genericHeaders: {
          'testHeaders': 'testHeaders',
          'testHeaders2': 'testHeaders2',
        },
        measureUploadSpeed: false,
      );

      nm.removeNotificationIdFor(nmFingerprint);

      return Future.value(true);
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  });
}