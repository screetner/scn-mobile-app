import 'dart:io';
import 'dart:convert';

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
  ProgressFileStore(this.progressFileDirectory) {
    if (!progressFileDirectory.existsSync()) {
      progressFileDirectory.createSync(recursive: true);
    }
  }

  Directory progressFileDirectory;

  @override
  Future<VideoSessionUploadProgress?> get(String fingerprint) async {
    final file = _getAsFile(fingerprint);

    if (!await file.exists()) {
      return null;
    }

    return await _commitTransaction(_loadFromFile, file, FileMode.read, FileLock.blockingShared);
  }

  @override
  Future<Map<String, VideoSessionUploadProgress>> getAll() async {
    try {
      final Map<String, VideoSessionUploadProgress> allProgress = {};

      final files = progressFileDirectory.listSync().whereType<File>();
      final uploadProgressFutures = files.map((file) async {
        final fingerprint = file.uri.pathSegments.last;
        final progress = await _commitTransaction(
            _loadFromFile, file, FileMode.read, FileLock.blockingShared);
        return MapEntry(fingerprint, progress);
      }).toList();

      final results = await Future.wait(uploadProgressFutures);
      for (final entry in results) {
        if (entry.value != null) {
          allProgress[entry.key] = entry.value!;
        }
      }

      return allProgress;
    } catch (e) {
      print('Error processing progress directory ${progressFileDirectory.path}: $e');
      rethrow;
    }
  }

  @override
  Future<void> remove(String fingerprint) async {
    final file = _getAsFile(fingerprint);

    if (!await file.exists()) {
      return;
    }

    await _commitTransaction((fileStream) async {
      await fileStream.truncate(0);
      await file.delete();
    }, file, FileMode.write, FileLock.blockingExclusive);
  }

  @override
  Future<void> set(String fingerprint, VideoSessionUploadProgress uploadProgress) async {
    final file = _getAsFile(fingerprint);

    if (!await file.exists()) {
      await file.create(recursive: true);
    }

    await _commitTransaction((fileStream) async {
      final contents = jsonEncode(uploadProgress.toJson());
      await fileStream.truncate(0);
      await fileStream.writeString(contents);
    }, file, FileMode.write, FileLock.blockingExclusive);
  }

  Future<VideoSessionUploadProgress> _loadFromFile(RandomAccessFile fileStream) async {
    final fileStreamLength = await fileStream.length();
    final fileContent = await fileStream.read(fileStreamLength);
    final contents = utf8.decode(fileContent);
    final Map<String, dynamic> jsonMap = jsonDecode(contents);
    return VideoSessionUploadProgress.fromJson(jsonMap);
  }

  Future<dynamic> _commitTransaction(Future<dynamic> Function(RandomAccessFile) transaction, File file, FileMode fileMode, FileLock fileLock) async {
    dynamic result;
    final fileSink = await file.open(mode: fileMode);
    try {
      await fileSink.lock(fileLock);
      result = await transaction(fileSink);
    } finally {
      await fileSink.unlock();
      await fileSink.close();
    }
    return result;
  }

  File _getAsFile(String fingerprint) {
    final sanitizedFingerprint = convertToFingerprint(fingerprint);
    final filePath = '${progressFileDirectory.path}/$sanitizedFingerprint';
    final file = File(filePath);
    return file;
  }

  static String convertToFingerprint(String fingerprint) {
    return fingerprint.replaceAll('/', '___');
  }
}