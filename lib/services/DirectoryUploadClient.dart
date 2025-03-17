import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:Screetner/services/models/DirectoryUploadStateStore.dart';
import 'package:Screetner/services/models/DirectoryUploadState.dart';
import 'package:tus_client_dart/tus_client_dart.dart';

import 'models/CustomTusFileStore.dart';

class DirectoryUploadClient{

  DirectoryUploadClient(
      this._uploadDirectory, {
        required Directory storeDirectory,
        this.maxChunkSize = 512 * 1024,
        this.retries = 0,
        this.retryScale = RetryScale.constant,
        this.retryInterval = 0,
      }) {
    try {
      _storeDirectory = storeDirectory;
      _store = DirectoryUploadFileStore(storeDirectory);
      _fingerprint = generateFingerprint() ?? "";
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> dispose() async {
    await cancelUpload();
  }

  Future<void> upload({
    dynamic Function(TusClient client, Duration? estimate)? onFileUploadStart,
    dynamic Function(double progressPercentage, Duration estimate)? onFileUploadProgress,
    dynamic Function()? onFileUploadComplete,
    Map<String, String>? Function(String filePath)? onAddUploadFileMetadata,
    Map<String, String>? Function(String filePath)? onAddUploadFileHeaders,
    required Uri tusServerUri,
    Map<String, String>? genericMetadata = const {},
    Map<String, String>? genericHeaders = const {},
    bool measureUploadSpeed = false,
  }) async {
    try {
      await setUploadState();

      await _uploadState.processAll((String filePath) async {
        try {
          print("UPLOADING: $filePath");
          await storeUploadState();
          final xFile = XFile(filePath);

          _currentTusClient = new TusClient(xFile,
            store: new CTusFileStore(storeDirectory),
            maxChunkSize: maxChunkSize ?? (512 * 1024),
            retries: retries ?? 0,
            retryScale: retryScale ?? RetryScale.constant,
            retryInterval: retryInterval = 0,
          );

          final dynamic Function(TusClient, Duration?)? onStart = (TusClient client, Duration? estimate) {
            return onFileUploadStart?.call(client, estimate);
          };

          final dynamic Function(double, Duration) onProgress = (double progressPercentage, Duration estimate) {
            final onGoingFileUploadProgress = ((progressPercentage / 100) * getFileSize(filePath)).round();
            _uploadState.setOnGoingFileUploadProgressBytes(filePath, onGoingFileUploadProgress);
            return onFileUploadProgress?.call(progressPercentage, estimate);
          };

          final dynamic Function() onComplete = () {
            onFileUploadComplete?.call();
          };

          final localMetadata = await getLocalData(filePath, genericMetadata, onAddUploadFileMetadata);
          final localHeaders = await getLocalData(filePath, genericHeaders, onAddUploadFileHeaders);

          await _currentTusClient!.upload(
            onStart: onStart,
            onProgress: onProgress,
            onComplete: onComplete,
            uri: tusServerUri,
            metadata: localMetadata,
            headers: localHeaders,
            measureUploadSpeed: measureUploadSpeed,
          );

        } catch (e, stackTrace) {
          // TODO: implement error handling
          print('An error occurred: $e');
          print('Stack trace: $stackTrace');
          throw e;
        }
      });

      await removeUploadState();
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }


  Future<bool> pauseUpload() async {
    try {
      return _currentTusClient?.pauseUpload() ?? true;
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<bool> cancelUpload() async {
    try {
      final result = await _currentTusClient?.cancelUpload() ?? true;
      await removeUploadState();
      return result;
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }


  // Methods for set/get up upload metadata

  Future<UploadState?> getUploadState() async {
    try {
      return await _store.get(_fingerprint);
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<UploadState> setUploadState() async {
    try {
      final storedUploadState = await _store.get(_fingerprint);
      _uploadState = storedUploadState == null
          ? UploadState(await getAllFileInDirectory(_uploadDirectory))
          : storedUploadState;

      return _uploadState;
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> storeUploadState() async {
    try {
      await _store.set(_fingerprint, _uploadState);
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> removeUploadState() async {
    try {
      await _store.remove(_fingerprint);
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }
  
  Future<Map<String, String>> getLocalData (
    String? filePath,
    Map<String, String>? genericData,
    Map<String, String>? Function(String filePath)? onUploadFileData
  ) async {
    try {
      return <String, String>{}..addAll(genericData ?? {})..addAll({
        if (filePath != null && onUploadFileData != null)
          ...onUploadFileData.call(filePath) ?? {}
      });
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }


  // Miscellaneous methods

  Future<Set<String>> getAllFileInDirectory(Directory directory, {bool followLinks = false}) async {
    try {
      if (!(await directory.exists())) {
        throw Exception('Directory does not exist');
      }

      Set<String> filePaths = {};

      final fileEntities = directory.list(
          recursive: true, followLinks: followLinks);

      await for (final entity in fileEntities) {
        if (entity is File) {
          filePaths.add(entity.path);
        }
      }

      return filePaths;
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  String? getCurrentFilePath() {
    return _uploadState.onGoingUploadFilePath;
  }

  int getTotalDirectorySize() {
    return _uploadState.getTotalUploadSize();
  }

  int getFileSize(String? filePath) {
    return UploadState.getFileSize(filePath);
  }

  int getUploadProgress() {
    return _uploadState.getTotalUploadProgress();
  }

  double getUploadProgressRatio() {
    final uploadProgress = getUploadProgress();
    final totalDirectorySize = getTotalDirectorySize();
    return uploadProgress / totalDirectorySize;
  }

  double getUploadProgressPercentage() {
    return getUploadProgressRatio() * 100;
  }

  String? generateFingerprint() {
    return getAsFingerprint(_uploadDirectory.path);
  }

  static String getAsFingerprint(String str) {
    return str.replaceAll(RegExp(r"\W+"), '_');
  }

  TusClient? get currentTusClient => _currentTusClient;

  TusClient? _currentTusClient = null;

  Directory get uploadDirectory => _uploadDirectory;
  Directory get storeDirectory => _storeDirectory;

  final Directory _uploadDirectory;
  late Directory _storeDirectory;
  late DirectoryUploadStoreI _store;
  late String _fingerprint;

  late UploadState _uploadState;

  int? maxChunkSize;
  int? retries;
  RetryScale? retryScale;
  int? retryInterval;
}