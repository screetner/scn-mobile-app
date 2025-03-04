import 'dart:async';
import 'dart:io';

import 'package:tus_client_background_demo/services/VideoSession.dart';
import 'package:tus_client_background_demo/services/models/ProgressFileStore.dart';
import 'package:tus_client_background_demo/services/models/SecureStorageCache.dart';
import 'package:tus_client_background_demo/types/ImmutableDirectoryUploadInput.dart';
import 'package:tus_client_background_demo/services/DirectoryUploadClient.dart';
import 'package:tus_client_background_demo/providers/NotificationManager.dart';
import 'package:tus_client_background_demo/types/api/VideoSession.dart';
import 'package:workmanager/workmanager.dart';

import '../types/ImmutableUploadManagerContext.dart';
import 'ApiClient.dart';
import 'VideoMetadataProvider.dart';

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

  Future<void> deleteDirectory({required Directory deleteDirectory}) async {
    deleteDirectory.deleteSync(recursive: true);

    final progressStore = new ProgressFileStore(DirectoryUploadManager().getContext().uploadProgressDirectory);
    final psFingerprint = ProgressFileStore.convertToFingerprint(deleteDirectory.path);
    await progressStore.remove(psFingerprint);
  }

  Future<void> uploadDirectory({required Directory uploadDirectory, int? chunkSize}) async {
    final tusdToken = (await ApiClient().getTusdToken())!;

    Map<String, dynamic> inputData = getWorkmanagerContext(
        uploadDirectory: uploadDirectory,
        tusdToken: tusdToken,
        chunkSize: chunkSize
    ).toJson();

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

  DirectoryUploadInput getWorkmanagerContext({required Directory uploadDirectory, required String tusdToken, int? chunkSize}) {
    return new DirectoryUploadInput(
      uploadDirectory: uploadDirectory,
      chunkSize: chunkSize,
      tusdServerUrl: _context.tusdServerUrl,
      apiUrl: _context.apiUrl,
      uploadProgressDirectory: _context.uploadProgressDirectory,
      tusStoreDirectory: _context.tusStoreDirectory,
      notificationChannelKey: _context.notificationChannelKey,
      notificationChannelGroupKey: _context.notificationChannelGroupKey,
      notificationChannelName: _context.notificationChannelName,
      notificationChannelGroupName: _context.notificationChannelGroupName,
      notificationChannelDescription: _context.notificationChannelDescription,
      notificationSoundSource: _context.notificationSoundSource,
      notificationDefaultColor: _context.notificationDefaultColor,
      notificationVibrationPattern: _context.notificationVibrationPattern,
      tusdToken: tusdToken,
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

      // Initializing Sequence
      final DirectoryUploadInput uploadInput = DirectoryUploadInput.toObject(
          inputData!);
      final UploadContext uploadContext = UploadContext.toObject(inputData);

      final NotificationManager nm = await NotificationManager.createInstance(uploadContext);

      final apiClient = await ApiClient.createInstance(uploadContext);
      final vs = await VideoSession.createInstance(apiClient);

      final tusdToken = uploadContext.tusdToken;

      final storeDirectory = uploadInput.tusStoreDirectory;

      final uploadProgressDirectory = uploadContext.uploadProgressDirectory;

      final uploadDirectory = uploadInput.uploadDirectory;
      final uploadDirectoryPath = uploadDirectory.path;
      final psFingerprint = ProgressFileStore.convertToFingerprint(uploadDirectoryPath);
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

      final progressStore = new ProgressFileStore(uploadProgressDirectory);

      final secureStorage = SecureStorageCache();
      final userId = await secureStorage.read(key: 'userId');
      final sessionName = uploadDirectoryPath.split('/').last;
      final sessionCloudName = sessionName + '_' + (userId ?? "");

      final videoSessionInfo = await VideoMetadataProvider().getVideoSessionInfo(uploadDirectory);
      final videoSessionId = videoSessionInfo.videoSessionId;

      // Uploading Sequence
      await vs.updateVideoSessionState(UpdateVideoSessionDTO(videoSessionId: videoSessionId!, uploadProgressPercentage: 0));
      final startingUP = VideoSessionUploadProgress(progress: 100.0, uploadState: VideoSessionUploadStateEnum.REQUESTING_UPLOAD);
      await progressStore.set(psFingerprint, startingUP);

      final setProgress = () async {
        final progress = uploadProgress();
        final up = VideoSessionUploadProgress(progress: progress, uploadState: VideoSessionUploadStateEnum.UPLOADING);
        nm.updateProgressBarFor(uploadDirectoryPath, progress);
        await progressStore.set(psFingerprint, up);
        final uploading_progress = progress < 100 ? progress.floor() : 99;
        await vs.updateVideoSessionState(UpdateVideoSessionDTO(videoSessionId: videoSessionId, uploadProgressPercentage: uploading_progress));
      };

      await client.upload(
        onFileUploadStart: (client, estimate) {
          // TODO: await async functions
          setProgress();
        },

        onFileUploadProgress: throttle((progressPercentage, estimate) {
          setProgress();
        }, const Duration(seconds: 1)),
        // Ensure that the progressBar won't be called more than once per second.

        onFileUploadComplete: () {
          setProgress();
          print("UPLOAD FINISHED");
        },

        // TODO: handle if the access token is expired
        tusServerUri: uploadInput.tusdServerUrl,
        genericMetadata: {
          'sessionName': sessionName,
          'sessionCloudName': sessionCloudName,
        },
        genericHeaders: {
          'AuthorizationTusd': 'Bearer ${tusdToken}',
        },
        measureUploadSpeed: false,
      );

      // Ending Sequence
      final finishingUP = VideoSessionUploadProgress(progress: 100.0, uploadState: VideoSessionUploadStateEnum.UPLOADED);
      nm.updateProgressBarFor(uploadDirectoryPath, finishingUP.progress);
      await vs.updateVideoSessionState(UpdateVideoSessionDTO(videoSessionId: videoSessionId, uploadProgressPercentage: 100));
      await progressStore.set(psFingerprint, finishingUP);

      await nm.removeNotificationIdFor(uploadDirectoryPath);

      return Future.value(true);
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  });
}