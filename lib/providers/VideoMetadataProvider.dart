import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:video_thumbnail/video_thumbnail.dart';
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
          final infoFile = File('${directory.path}/information.json');
          final infoJsonString = await infoFile.readAsString();
          final info = jsonDecode(infoJsonString);

          final videoTlocTuples = info['videoTlocTuples'] ?? [];
          final firstVideoName = videoTlocTuples.first['videoName'] ?? "";
          final firstVideoPath = '${directory.path}/$firstVideoName';
          final thumbnail = await _getThumbnail(firstVideoPath);

          final sessionName = directory.path
              .split('/')
              .last
              .split('.')
              .first;
          final sessionTitle = parseAndFormatUnixTimestamp(sessionName) ??
              sessionName;

          return VideoInfo(
              thumbnail: thumbnail,
              sessionTitle: sessionTitle,
              sessionDirectory: directory
          );
        } catch (e, stackTrace) {
          return VideoInfo(
              thumbnail: null,
              sessionTitle: e.toString(),
              sessionDirectory: directory
          );
        }
      }).toList();

      List<VideoInfo> batchResults = await Future.wait(batchFutures);
      recordInfoList.addAll(batchResults);
    }

    return recordInfoList;
  }

  List<Directory> getVideoSessions() {
    return _recordDirectory
        .listSync()
        .where((item) => item is Directory)
        .map((item) => Directory(item.path))
        .toList();
  }

  Future<Uint8List?> _getThumbnail(String filePath) async {
    return VideoThumbnail.thumbnailData(
      video: filePath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 128,
      quality: 75,
    );
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
  final String sessionTitle;
  final Directory sessionDirectory;

  ImmutableVideoInformation({
    Uint8List? this.thumbnail,
    int? this.frameCount,
    required this.sessionTitle,
    required this.sessionDirectory,
  }) {}
}

typedef VideoInfo = ImmutableVideoInformation;