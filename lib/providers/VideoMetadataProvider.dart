import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:tus_client_background_demo/services/DirectoryUploadClient.dart';
import 'package:tus_client_background_demo/services/models/SecureStorageCache.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
import '../types/ImmutableVideoRecordManagerContext.dart';

class VideoMetadataProvider {
  bool _isInitialized = false;

  late Directory _recordDirectory;

  VideoMetadataProvider._privateConstructor();

  static final VideoMetadataProvider _instance = VideoMetadataProvider._privateConstructor();

  factory VideoMetadataProvider() {
    return _instance;
  }

  Future<void> initialize(RecordContext context) async {
    if (_isInitialized) {
      return;
    }

    _recordDirectory = context.recordDirectory;

    if(!_recordDirectory.existsSync()) {
      _recordDirectory.createSync(recursive: true);
    }

    _isInitialized = true;
  }

  Future<List<VideoInfo>> getVideoInfo() async {
    final List<Directory> recordSessions = getVideoSessions();

    final recordsCount = recordSessions.length;
    final batchSize = 10;

    List<VideoInfo> recordInfoList = [];
    for(int i = 0; i < recordsCount; i += batchSize) {
      final batch = recordSessions.sublist(i, min(i + batchSize, recordsCount));

      List<Future<VideoInfo>> batchFutures = batch.map((Directory directory) async {
        try {
          final info = await getVideoSessionInfo(directory);

          final videoTlocTuples = info.videoTlocTuples;
          final firstVideoName = videoTlocTuples.first.videoName;
          final firstVideoPath = '${directory.path}/$firstVideoName';
          final thumbnail = await _getThumbnail(firstVideoPath);

          final secureStorage = SecureStorageCache();
          final userId = await secureStorage.read(key: 'userId');
          final sessionName = directory.path
              .split('/')
              .last
              .split('.')
              .first;
          final sessionTitle = parseAndFormatUnixTimestamp(sessionName) ?? sessionName;
          final sessionCloudDirectory = sessionTitle + '_' + (userId ?? "");

          return VideoInfo(
            thumbnail: thumbnail,
            sessionTitle: sessionTitle,
            sessionDirectory: directory,
            fingerprint: DirectoryUploadClient.getAsFingerprint(directory.path)
          );
        } catch (e, stackTrace) {
          return VideoInfo(
              thumbnail: null,
              sessionTitle: e.toString(),
              sessionDirectory: directory,
            fingerprint: DirectoryUploadClient.getAsFingerprint(directory.path)
          );
        }
      }).toList();

      List<VideoInfo> batchResults = await Future.wait(batchFutures);
      recordInfoList.addAll(batchResults);
    }

    return recordInfoList;
  }

  Future<ImmutableVideoSessionInformation> getVideoSessionInfo(Directory directory) async {
    final infoFile = File('${directory.path}/information.json');
    final infoJsonString = await infoFile.readAsString();
    final info = jsonDecode(infoJsonString);

    return ImmutableVideoSessionInformation.fromJson(info);
  }

  List<Directory> getVideoSessions() {
    return _recordDirectory
        .listSync()
        .where((item) => item is Directory)
        .map((item) => Directory(item.path))
        .toList();
  }

  Future<Uint8List?> _getThumbnail(String filePath) async {
    // TODO: change this once we can use video thumbnail
    return null;

    // return VideoThumbnail.thumbnailData(
    //   video: filePath,
    //   imageFormat: ImageFormat.JPEG,
    //   maxWidth: 128,
    //   quality: 75,
    // );
  }

  String? parseAndFormatUnixTimestamp(String input) {
    const weekdayArray = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthArray = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    final timestamp = int.tryParse(input);
    if (timestamp == null) {
      return null;
    }


    // Convert the timestamp to DateTime
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    final hour = dateTime.hour.toString();
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final weekday = weekdayArray[dateTime.weekday];
    final date = dateTime.day.toString();
    final month = monthArray[dateTime.month];
    final year = dateTime.year.toString();
    return '$hour:$minute $weekday $date $month $year';
  }

  /// The 'video record directory path'
  Directory get recordDirectory => _recordDirectory;
}

class ImmutableVideoInformation {
  final Uint8List? thumbnail;
  final int? frameCount;
  final String fingerprint;
  final String sessionTitle;
  final Directory sessionDirectory;

  ImmutableVideoInformation({
    Uint8List? this.thumbnail,
    int? this.frameCount,
    required this.fingerprint,
    required this.sessionTitle,
    required this.sessionDirectory,
  }) {}
}

typedef VideoInfo = ImmutableVideoInformation;

class ImmutableVideoSessionInformation {
  final int videoCount;
  final String sessionStartTime;
  final List<VideoTlocTuples> videoTlocTuples;
  final String videoSessionId;

  ImmutableVideoSessionInformation ({
    required this.videoCount,
    required this.sessionStartTime,
    required this.videoTlocTuples,
    required this.videoSessionId,
  }) {}

  factory ImmutableVideoSessionInformation.fromJson(Map<String, dynamic> json) {
    final videoTlocTuplesJson = json['videoTlocTuples'] as List;
    List<VideoTlocTuples> videoTlocTuplesList = videoTlocTuplesJson.map((i) => VideoTlocTuples.fromJson(i)).toList();

    return ImmutableVideoSessionInformation(
      videoCount: json['videoCount'],
      sessionStartTime: json['sessionStartTime'],
      videoTlocTuples: videoTlocTuplesList,
      videoSessionId: json['videoSessionId'],
    );
  }
}

class VideoTlocTuples {
  final String videoName;
  final String tlocName;

  VideoTlocTuples ({
    required this.videoName,
    required this.tlocName,
  }) {}

  factory VideoTlocTuples.fromJson(Map<String, dynamic> json) {
    return VideoTlocTuples(
      videoName: json['videoName'],
      tlocName: json['tlocName'],
    );
  }
}