import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:tus_client_background_demo/types/ImmutableUploadManagerContext.dart';
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
    required super.apiUrl,
    required super.tusStoreDirectory,
    required super.uploadProgressDirectory,
    required super.notificationChannelKey,
    required super.notificationChannelGroupKey,
    required super.tusdToken,
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

  Map<String, dynamic> toJson() {
    Map<String,dynamic> map = {
      ...super.toJson(),
      'upload_directory_path': uploadDirectory.path,
      'chunk_size': chunkSize,
    };

    // Remove keys with null values
    map.removeWhere((key, value) => value == null);
    return map;
  }

  static ImmutableDirectoryUploadInput toObject(Map<String, dynamic> input) {
    final uploadContext = ImmutableUploadManagerContext.toObject(input);

    return new ImmutableDirectoryUploadInput(
      uploadDirectory: Directory(input['upload_directory_path']!),
      tusdServerUrl: uploadContext.tusdServerUrl,
      apiUrl: uploadContext.apiUrl,
      tusStoreDirectory: uploadContext.tusStoreDirectory,
      uploadProgressDirectory: uploadContext.uploadProgressDirectory,
      notificationChannelKey: uploadContext.notificationChannelKey,
      notificationChannelGroupKey: uploadContext.notificationChannelGroupKey,
      chunkSize: input['chunk_size'],
      notificationChannelName: uploadContext.notificationChannelName,
      notificationChannelGroupName: uploadContext.notificationChannelGroupName,
      notificationChannelDescription: uploadContext.notificationChannelDescription,
      notificationSoundSource: uploadContext.notificationSoundSource,
      notificationDefaultColor: uploadContext.notificationDefaultColor,
      notificationVibrationPattern: uploadContext.notificationVibrationPattern,
      tusdToken: uploadContext.tusdToken,
    );
  }
}

typedef DirectoryUploadInput = ImmutableDirectoryUploadInput;
