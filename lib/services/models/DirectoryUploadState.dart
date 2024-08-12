import 'dart:collection';
import 'dart:io';

class DirectoryUploadState {
  late Queue<String> _uploadFilePathsQueue;
  final Set<String> _finishedUploadFilePaths = {};
  String? _onGoingUploadFilePath;


  String? get onGoingUploadFilePath => _onGoingUploadFilePath;

  DirectoryUploadState(Iterable<String> uploadFilePaths) {
    try {
      final uploadFilePathsList = List.of(uploadFilePaths);
      uploadFilePathsList.sort((a, b) {
        final fileA = File(a);
        final fileB = File(b);
        final sizeA = fileA.lengthSync();
        final sizeB = fileB.lengthSync();
        return sizeA.compareTo(sizeB);
      });

      _uploadFilePathsQueue = Queue.of(uploadFilePathsList);
    } catch (e) {
      // TODO: implement catch function
      throw new UnimplementedError();
    }
  }

  _setOnGoingUploadFilePath(String? filePath) {
    _onGoingUploadFilePath = filePath;
  }

  _setFinishedUploadFilePaths(Iterable<String> filePaths) {
    _finishedUploadFilePaths.clear();
    _finishedUploadFilePaths.addAll(filePaths);
  }

  /// Moves the current file to the finished set and loads the next file
  ///
  /// Returns `true` if there is still a file in the queue, `false` otherwise.
  bool iterate() {
    if (_onGoingUploadFilePath != null) {
      _finishedUploadFilePaths.add(_onGoingUploadFilePath!);
      _isFinishedFileSizeCacheDirty = true;
    }

    _onGoingUploadFilePath = _uploadFilePathsQueue.isEmpty
        ? null
        : _uploadFilePathsQueue.removeFirst();

    _isCurrentFileSizeCacheDirty = true;

    return _onGoingUploadFilePath != null;
  }

  Future<void> processAll(Future<void> Function(String filePath) task) async {
    do {
      if(_onGoingUploadFilePath != null) {
        await task(_onGoingUploadFilePath!);
      }
    } while (iterate());
  }

  Map<String, dynamic> toJson() =>
      {
        'upload_file_paths_queue': _uploadFilePathsQueue.toList(),
        'on_going_upload_file_path': _onGoingUploadFilePath,
        'finished_upload_file_paths': _finishedUploadFilePaths.toList(),
      };

  static DirectoryUploadState toObject(Map<String, dynamic> inputData) {
    try {
      final List<String> uploadFilePathsList = List<String>.from(inputData['upload_file_paths_queue']);
      final String? onGoingUploadFilePath = inputData['on_going_upload_file_path'];
      final List<String> finishedUploadFilePaths = List<String>.from(inputData['finished_upload_file_paths']);

      final dus = DirectoryUploadState(uploadFilePathsList);
      dus._setOnGoingUploadFilePath(onGoingUploadFilePath);
      dus._setFinishedUploadFilePaths(finishedUploadFilePaths);

      return dus;
    } catch (e) {
      //TODO: implement the catch function
      throw new UnimplementedError();
    }
  }

  /// Calculates the total file size of all files in the current upload queue,
  /// the ongoing upload file, and the finished upload files.
  ///
  /// Returns the total size in bytes.
  int getTotalFileSize() {
    if(!_isTotalFileSizeCacheDirty) {
      return _totalFileSizeCache;
    }

    int totalSize = 0;

    totalSize += getFinishedFileSize();

    totalSize += getCurrentFileSize();

    for (final filePath in _uploadFilePathsQueue) {
      totalSize += getFileSize(filePath);
    }

    _totalFileSizeCache = totalSize;
    _isTotalFileSizeCacheDirty = false;

    return totalSize;
  }

  /// Computes the total file size of all files that have been marked as finished.
  ///
  /// Returns the total size in bytes.
  int getFinishedFileSize() {
    if(!_isFinishedFileSizeCacheDirty) {
      return _finishedFileSizeCache;
    }

    int totalSize = 0;

    for (final filePath in _finishedUploadFilePaths) {
      totalSize += getFileSize(filePath);
    }

    _finishedFileSizeCache = totalSize;
    _isFinishedFileSizeCacheDirty = false;

    return totalSize;
  }

  int getCurrentFileSize() {
    if(!_isCurrentFileSizeCacheDirty) {
      return _currentFileSizeCache;
    }

    _currentFileSizeCache = getFileSize(_onGoingUploadFilePath);
    return _currentFileSizeCache;
  }

  static int getFileSize (String? filePath) {
    if(filePath == null) return 0;

    final file = File(filePath);
    return file.existsSync() ? file.lengthSync() : 0;
  }

  late int _totalFileSizeCache;
  bool _isTotalFileSizeCacheDirty = true;

  late int _finishedFileSizeCache;
  bool _isFinishedFileSizeCacheDirty = true;

  late int _currentFileSizeCache;
  bool _isCurrentFileSizeCacheDirty = true;
}

typedef UploadState = DirectoryUploadState;