import 'dart:io';
import 'dart:math';

import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as path;
import 'package:tus_client_background_demo/model/DirectoryUploadStore.dart';
import 'package:http/http.dart' as http;
import 'package:speed_test_dart/classes/server.dart';
import 'package:tus_client_dart/tus_client_dart.dart';

class DirectoryUploadClient{

  DirectoryUploadClient(
      this.directory, {
        required this.store,
        this.maxChunkSize = 512 * 1024,
        this.retries = 0,
        this.retryScale = RetryScale.constant,
        this.retryInterval = 0,
      }) {
    _fingerprint = generateFingerprint() ?? "";
  }

  Future<void> dispose() async {
    await cancelUpload();
  }

  Future<void> upload({
    Function(TusClient client, Duration? estimate)? onFileUploadStart,
    Function(double totalProgressPercentage, Duration maxEstimation)? onDirectoryUploadProgress,
    Function()? onFileUploadComplete,
    required Uri uri,
    Map<String, String>? metadata = const {},
    Map<String, String>? headers = const {},
    bool measureUploadSpeed = false,
  }) async {
    setUploadData(uri, headers, metadata);

    // reading directory
    // setting _uploadFilesPath, store
    await upsertUploadUrl();

    // fetch upload progress
    // setting _estimateUploadProgressSecond, _progressByte, _progressRatio, _fileSize, and _totalDirectorySize
    await fetchUploadProgress();

    // creating tus clients
    // setting _tusClientList
    await createTusClients();

    // upload
    print("EXECUTING CLIENTS");

    List<TusClient> clonedTusClientList = List.from(_tusClientList);
    Set<TusClient> removingTusClientSet = {};
  //   final directoryUploadFutures = _tusClientList.map((tusClient) async {
  //
  // }).toList();

    for(final tusClient in clonedTusClientList) {
      Map<String, String> localMetadata = {};
      if(metadata != null)
        localMetadata.addAll(metadata);

      String relativePath = './' + path.relative(tusClient.file.path, from: directory.path);
      localMetadata['device_relative_path'] = relativePath;

      print("UPLOAD INDIVIDUAL CLIENT");
      await tusClient.upload(
          uri: uri,
          metadata: localMetadata,
          headers: headers,
          measureUploadSpeed: measureUploadSpeed,
          onStart: (client, estimate) {
            onFileUploadStart?.call(client, estimate);
          },
          onProgress: (individualProgressPercentage, estimate) {
            final filePath = tusClient.file.path;
            updateUploadProgress(filePath)(individualProgressPercentage);
            final totalProgressPercentage = getTotalUploadProgressPercentage();
            final maxEstimation = measureUploadSpeed ? Duration(seconds: getMaxEstimationSecond()) : Duration(seconds: maxInt);
            onDirectoryUploadProgress?.call(totalProgressPercentage, maxEstimation);
          },
          onComplete: () {
            removingTusClientSet.add(tusClient);
            _tusClientList.remove(tusClient);
            onFileUploadComplete?.call();
          }
      );
    }

    _tusClientList.removeWhere((tusClient) => removingTusClientSet.contains(tusClient));

    // await Future.wait(directoryUploadFutures);

    print("Upload Done/Paused");

    if(await getTotalUploadProgress() == _totalDirectorySize)
      await onCompleteUpload();
  }


  Future<bool> pauseUpload() async {
    try {
      final pauseUploadFutures = _tusClientList.map((client) async => client.pauseUpload()).toList();
      await Future.wait(pauseUploadFutures);
      return true;
    } catch (e) {
      throw Exception("Error pausing upload: $e");
    }
  }

  Future<bool> cancelUpload() async {
    try {
      await pauseUpload();
      await store.remove(_fingerprint);
    return true;
    } catch (_) {
    throw Exception("Error cancelling upload");
    }
  }
  
  Future<void> onCompleteUpload() async {
    await store.remove(_fingerprint);
  }

  // Methods for set/get up upload metadata

  Function(double) updateUploadProgress(String filepath) {
    return (double progressPercentage) {
      double progressRatio = progressPercentage / 100;
      _progressRatio[filepath] = progressRatio;
      // Note: I use round() here to avoid floating point error
      final fileSize = _fileSize[filepath]!;
      _progressByte[filepath] = max((progressRatio * fileSize).round(), fileSize);
    };
  }

  void setUploadData(
      Uri url,
      Map<String, String>? headers,
      Map<String, String>? metadata,
      ) {
    this.url = url;
    this.headers = headers;
    this.metadata = metadata;
  }

  int? _parseOffset(String? offset) {
    if (offset == null || offset.isEmpty) {
      return null;
    }
    if (offset.contains(",")) {
      offset = offset.substring(0, offset.indexOf(","));
    }
    return int.tryParse(offset);
  }

  // Methods for setting up tus clients

  /// Creates a list of `TusClient` instances for ongoing uploads.
  ///
  /// This method retrieves the unfinished uploads and creates
  /// a [TusClient] instance for each file being uploaded.
  /// The [TusClient] instances are then stored in the [_tusClientList] for later use.
  ///
  /// Returns: A `List<TusClient>` that is stored in [_tusClientList]
  Future<List<TusClient>> createTusClients() async {
    try {
      final uploads = await getOngoingUploadsMap();

      final tusClients = uploads.entries.map((entry) {
        return new TusClient(
          XFile(entry.key),
          store: TusMemoryStore(),
          maxChunkSize: maxChunkSize,
          retries: retries,
          retryScale: retryScale,
          retryInterval: retryInterval,
        );
      }).toList();

      _tusClientList = tusClients;

      return tusClients;
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  /// Retrieves a map of ongoing uploads by filtering out completed uploads.
  ///
  /// Returns:
  /// - A [Map<String, Uri>] where the keys are file paths and the values are the associated upload URIs for unfinished uploads.
  ///
  /// Example usage:
  /// ```dart
  /// final ongoingUploads = await getOngoingUploadsMap();
  /// ```
  Future<Map<String, Uri>> getOngoingUploadsMap() async {
    final uploadUrlMaps = await store.get(_fingerprint);

    Map<String, Uri> filteredMap = {};
    filteredMap.addAll(uploadUrlMaps);

    filteredMap.removeWhere((filePath, _) => _progressByte[filePath]! >= _fileSize[filePath]!);

    return filteredMap;
  }


  // Methods for reading upload progress from server

  /// Fetches the upload progress from the tus server for each files found in [store] and updates the following variables:
  ///
  /// - [_estimateUploadProgressSecond]: A map that estimates the remaining upload time for each file.
  /// - [_progressByte]: A map containing the current upload progress (in bytes) for each file.
  /// - [_progressRatio]: A map containing the ratio of uploaded bytes to the total file size for each file.
  /// - [_fileSize]: A map containing the size (in bytes) of each file being uploaded.
  /// - [_totalDirectorySize]: The total size of all files in the directory combined.
  ///
  /// Returns: A [Map<String, int>] containing the file paths as keys and their current upload progress (in bytes) as values.
  ///
  /// Example usage:
  /// ```dart
  /// final uploadProgressMap = await fetchUploadProgress();
  /// print('Upload Progress: $uploadProgressMap');
  /// ```
  Future<Map<String, int>> fetchUploadProgress() async {
    try {
      final uploadUrlMaps = await store.get(_fingerprint);
      final uploadUrlMapsEntries = uploadUrlMaps.entries;
      Map<String, int> estimateUploadMap = {};
      Map<String, int> uploadProgressMap = {};
      Map<String, int> fileSizeMap = {};
      Map<String, double> uploadProgressRatioMap = {};

      final uploadProgressFuture = uploadUrlMapsEntries.map((entry) async {
        final filePath = entry.key;
        final uri = entry.value;
        final progress = await fetchIndividualUploadProgress(uri);
        return MapEntry(filePath, progress);
      }).toList();

      final uploadProgress = await Future.wait(uploadProgressFuture);

      for (final entry in uploadProgress) {
        final key = entry.key;
        final value = entry.value;

        uploadProgressMap[key] = value;
        fileSizeMap[key] = await XFile(key).length();
        uploadProgressRatioMap[key] = fileSizeMap[key]! != 0 ?
            uploadProgressMap[key]! / fileSizeMap[key]! :
            1;
        estimateUploadMap[key] = maxInt;
      }

      _estimateUploadProgressSecond = estimateUploadMap;
      _progressByte = uploadProgressMap;
      _progressRatio = uploadProgressRatioMap;
      _fileSize = fileSizeMap;
      _totalDirectorySize = fileSizeMap.values.isNotEmpty
          ? fileSizeMap.values.reduce((sum, size) => sum + size)
          : 0;
      return uploadProgressMap;
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');

      throw e;
    }
  }

  Future<int> fetchIndividualUploadProgress(Uri uploadUri) async {
    try {
      final client = http.Client();

      final offsetHeaders = {"Tus-Resumable": tusVersion};
      final response = await client.head(
          uploadUri, headers: offsetHeaders);

      if (!(response.statusCode >= 200 && response.statusCode < 300)) {
        throw ProtocolException(
          "Unexpected error while resuming upload",
          response.statusCode,
        );
      }

      client.close();

      int? serverOffset = _parseOffset(response.headers["upload-offset"]);
      if (serverOffset == null) {
        throw ProtocolException(
            "missing upload offset in response for resuming upload");
      }

      return serverOffset;
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');

      throw e;
    }
  }

  double getTotalUploadProgressPercentage() {
    final progressValues = _progressByte.values;

    if (progressValues.isEmpty) {
      return 1;
    }

    final totalProgress = progressValues.fold<int>(0, (sum, value) => sum + value);

    return (totalProgress / _totalDirectorySize!) * 100;
  }

  int getMaxEstimationSecond() {
    if(_estimateUploadProgressSecond.isEmpty) {
      return 0;
    }

    return _estimateUploadProgressSecond.values.reduce(max);
  }

  Future<int> getTotalUploadProgress() async {
    return _progressByte.values.isNotEmpty ? _progressByte.values.reduce((sum, size) => sum + size) : 0;
  }

  // Methods for reading directory

  /// Updates or inserts upload URIs for all files found in the specified directory to the [store].
  ///
  /// This method performs the following operations:
  /// - Collects all file paths in the target directory and updates the [_uploadFilesPath] list.
  /// - Creates a new tus upload URIs to the tus server for any files that do not already have an associated upload URIs in the [store].
  /// - Updates the [store] with the new upload URIs for the newly inserted files.
  /// - Calculates the total size of all files in the directory and updates the [_totalDirectorySize] variable.
  ///
  /// Returns: `Map<String, Uri>` containing the file paths as keys and their associated upload URIs as values.
  ///
  /// Throws: An error if any step in the process fails.
  ///
  /// Example usage:
  /// ```dart
  /// final uploadUriMap = await upsertUploadUrl();
  /// print('Upload URIs: $uploadUriMap');
  /// ```
  Future<Map<String, Uri>> upsertUploadUrl() async {
    try {
      final uploadUrlMaps = await store.get(_fingerprint);
      final existingFileUploadsPath = uploadUrlMaps.keys.toSet();

      print("uploadUrlMaps: ${uploadUrlMaps}");
      print("existingFileUploadsPath: ${existingFileUploadsPath}");

      _uploadFilesPath = await getAllFileInDirectory(directory.path);

      print("_uploadFilesPath: ${_uploadFilesPath}");

      // Create new upload for new files
      final createUploadFutures = _uploadFilesPath
          .where((filePath) => !existingFileUploadsPath.contains(filePath))
          .map((filePath) async {
        final tusClient = TusClient(XFile(filePath), store: TusMemoryStore());
        tusClient.setUploadData(url, headers, metadata);

        await tusClient.createUpload();
        return MapEntry(filePath, tusClient.uploadUrl!);
      }).toList();

      final Map<String, Uri> newUploadUrlMapsList = Map.fromEntries(await Future.wait(createUploadFutures));
      uploadUrlMaps.addAll(newUploadUrlMapsList);

      store.set(_fingerprint, uploadUrlMaps);
      return uploadUrlMaps;

    } catch(e, stackTrace) {
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');

      if (e is FileSystemException) {
        print('File system error: ${e.message}');
      }else {
        print('Unexpected error: ${e.toString()}');
      }

      throw e;
    }
  }

  Future<Set<String>> getAllFileInDirectory(String directoryPath, {bool followLinks = false}) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
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


  // Miscellaneous methods

  String? generateFingerprint() {
    return directory.path.replaceAll(RegExp(r"\W+"), '_');
  }


  // file upload data

  final tusVersion = "1.0.0";
  late Uri url;
  Map<String, String>? metadata;
  Map<String, String>? headers;
  double? uploadSpeed;
  List<Server>? bestServers;

  int maxChunkSize;
  int retries;
  RetryScale retryScale;
  int retryInterval;


  // object data

  DirectoryUploadStoreI store;

  Directory directory;

  List<TusClient> _tusClientList = [];

  Map<String, double> _progressRatio = {};
  Map<String, int> _progressByte = {};
  Map<String, int> _fileSize = {};
  Map<String, int> _estimateUploadProgressSecond = {};

  int? _totalDirectorySize;

  String _fingerprint = "";

  String? _uploadMetadata;

  Set<String> _uploadFilesPath = {};

  static const int maxInt = 0x7FFFFFFFFFFFFFFF;

  // object data getters

  /// The URI on the server for the file
  Set<String> get uploadFilesPath => _uploadFilesPath;

  /// The fingerprint of the file being uploaded
  String get fingerprint => _fingerprint;

  /// The 'Upload-Metadata' header sent to server
  String get uploadMetadata => _uploadMetadata ?? "";

  /// Get the total upload size
  String get totalDirectorySize => totalDirectorySize;

}