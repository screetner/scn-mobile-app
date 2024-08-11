import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:tus_client_background_demo/context/ImmutableUploadManagerContext.dart';
import 'package:tus_client_dart/tus_client_dart.dart';

class ImmutableDirectoryUploadInput extends ImmutableUploadManagerContext{
  final Directory uploadDirectory;
  final int? chunkSize;
  final int? retries;
  final RetryScale? retryScale;
  final int? retryInterval;

  ImmutableDirectoryUploadInput({
    required this.uploadDirectory,
    required super.tusdServerUrl,
    required super.tusStoreDirectory,
    required super.notificationChannelKey,
    required super.notificationChannelGroupKey,
    int? this.chunkSize,
    int? this.retries,
    RetryScale? this.retryScale,
    int? this.retryInterval,
    String? super.notificationChannelName,
    String? super.notificationChannelGroupName,
    String? super.notificationChannelDescription,
    String? super.notificationSoundSource,
    Color? super.notificationDefaultColor,
    Int64List? super.notificationVibrationPattern,
  }) {}

  Map<String, dynamic> getAsMap() {
    Map<String,dynamic> map = {
      ...super.getAsMap(),
      'upload_directory_path': uploadDirectory.path,
      'chunk_size': chunkSize,
    };

    // Remove keys with null values
    map.removeWhere((key, value) => value == null);
    return map;
  }

  static ImmutableDirectoryUploadInput getAsObject(Map<String, dynamic> input) {
    final uploadContext = ImmutableUploadManagerContext.getAsContext(input);

    return new ImmutableDirectoryUploadInput(
      uploadDirectory: Directory(input['upload_directory_path']!),
      tusdServerUrl: uploadContext.tusdServerUrl,
      tusStoreDirectory: uploadContext.tusStoreDirectory,
      notificationChannelKey: uploadContext.notificationChannelKey,
      notificationChannelGroupKey: uploadContext.notificationChannelGroupKey,
      chunkSize: input['chunk_size'],
      notificationChannelName: uploadContext.notificationChannelName,
      notificationChannelGroupName: uploadContext.notificationChannelGroupName,
      notificationChannelDescription: uploadContext.notificationChannelDescription,
      notificationSoundSource: uploadContext.notificationSoundSource,
      notificationDefaultColor: uploadContext.notificationDefaultColor,
      notificationVibrationPattern: uploadContext.notificationVibrationPattern,
    );
  }
}

typedef DirectoryUploadInput = ImmutableDirectoryUploadInput;
