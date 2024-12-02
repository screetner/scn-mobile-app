import 'dart:io';
import 'dart:convert';
import 'package:synchronized/synchronized.dart';

enum VideoSessionUploadStateEnum {
  UNUPLOADED,
  REQUESTING_UPLOAD,
  UPLOADING,
  UPLOADED,
}

class VideoSessionUploadProgress {
  VideoSessionUploadProgress({
    required this.progress,
    required this.uploadState
  });

  final double progress;
  final VideoSessionUploadStateEnum uploadState;

  Map<String, dynamic> toJson() => {
    'progress': progress,
    'uploadState': uploadState.index,
  };

  static VideoSessionUploadProgress fromJson(Map<String, dynamic> json) {
    return VideoSessionUploadProgress(
      progress: json['progress'],
      uploadState: VideoSessionUploadStateEnum.values[json['uploadState']],
    );
  }
}

abstract class ProgressStore {
  Future<void> set(String fingerprint, VideoSessionUploadProgress uploadProgress);

  Future<VideoSessionUploadProgress?> get(String fingerprint);

  Future<void> remove(String fingerprint);

  Future<Map<String, VideoSessionUploadProgress>> getAll();
}

class ProgressFileStore implements ProgressStore {
  ProgressFileStore(this.file);

  final File file;
  Map<String, VideoSessionUploadProgress> _progressMap = {};
  final _lock = Lock();

  Future<void> _loadFromFile() async {
    await _lock.synchronized(() async {
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> jsonMap = jsonDecode(contents);
        _progressMap = jsonMap.map((key, value) => MapEntry(key, VideoSessionUploadProgress.fromJson(value)));
      }
    });
  }

  Future<void> _saveToFile() async {
    await _lock.synchronized(() async {
      final jsonMap = _progressMap.map((key, value) => MapEntry(key, value.toJson()));
      final contents = jsonEncode(jsonMap);
      await file.writeAsString(contents, mode: FileMode.writeOnly, flush: true);
    });
  }

  @override
  Future<void> set(String fingerprint, VideoSessionUploadProgress uploadProgress) async {
    await _loadFromFile();
    _progressMap[fingerprint] = uploadProgress;
    await _saveToFile();
  }

  @override
  Future<VideoSessionUploadProgress?> get(String fingerprint) async {
    await _loadFromFile();
    return _progressMap[fingerprint];
  }

  @override
  Future<void> remove(String fingerprint) async {
    await _loadFromFile();
    _progressMap.remove(fingerprint);
    await _saveToFile();
  }

  @override
  Future<Map<String, VideoSessionUploadProgress>> getAll() async {
    await _loadFromFile();
    return _progressMap;
  }
}