import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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
    final List<Directory> recordSessions = await getVideoFiles();

    final recordsCount = recordSessions.length;
    final batchSize = 10;

    // NOTE: We cannot run more than 10 ffprobe executions at a time.
    List<VideoInfo> recordInfoList = [];
    for(int i = 0; i < recordsCount; i += batchSize) {
      final batch = recordSessions.sublist(i, min(i + batchSize, recordsCount));

      List<Future<VideoInfo>> batchFutures = batch.map((Directory directory) async {
        final infoFile = File('${directory.path}/information.json');
        final infoJsonString = await infoFile.readAsString();
        final info = jsonDecode(infoJsonString);

        final frameCount = info['frameCount'] ?? 0;
        final firstFrameName = info['firstFrameName'] ?? "";
        final thumbnail = await _getThumbnail('${directory.path}/$firstFrameName');

        final sessionName = directory.path.split('/').last.split('.').first;
        final videoTitle = parseAndFormatUnixTimestamp(sessionName) ?? sessionName;

        return VideoInfo(
          thumbnail: thumbnail,
          frameCount: frameCount,
          videoTitle: videoTitle,
        );
      }).toList();

      List<VideoInfo> batchResults = await Future.wait(batchFutures);
      recordInfoList.addAll(batchResults);
    }

    return recordInfoList;
  }

  Future<List<Directory>> getVideoFiles() async {
    return _recordDirectory
        .listSync()
        .where((item) => item is Directory)
        .map((item) => Directory(item.path))
        .toList();
  }

  Future<Uint8List?> _getThumbnail(String filePath) async {

    if (filePath.isNotEmpty &&
        (filePath.toLowerCase().endsWith('.jpg') || filePath.toLowerCase().endsWith('.jpeg'))) {
      final firstFrameFile = File(filePath);
      if (await firstFrameFile.exists()) {
        return await firstFrameFile.readAsBytes();
      }
    }

    return null;
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
  final String? videoTitle;

  ImmutableVideoInformation({
    Uint8List? this.thumbnail,
    int? this.frameCount,
    String? this.videoTitle
  }) {}
}

typedef VideoInfo = ImmutableVideoInformation;