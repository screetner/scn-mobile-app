import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

class ImmutableUploadManagerContext {
  final Uri tusdServerUrl;
  final Directory tusStoreDirectory;
  final File progressStoreFile;
  final String notificationChannelKey;
  late final String notificationChannelKeySilent;
  late final String notificationChannelKeyAudible;
  final String notificationChannelGroupKey;
  final String? notificationChannelName;
  final String? notificationChannelGroupName;
  final String? notificationChannelDescription;
  final String? notificationSoundSource;
  final Color? notificationDefaultColor;
  final Int64List? notificationVibrationPattern;
  final String? tusdToken;

  ImmutableUploadManagerContext({
    required this.tusdServerUrl,
    required this.tusStoreDirectory,
    required this.progressStoreFile,
    required this.notificationChannelKey,
    required this.notificationChannelGroupKey,
    required this.tusdToken,
    String? this.notificationChannelName,
    String? this.notificationChannelGroupName,
    String? this.notificationChannelDescription,
    String? this.notificationSoundSource,
    Color? this.notificationDefaultColor,
    Int64List? this.notificationVibrationPattern,
  }) {
    notificationChannelKeySilent = notificationChannelKey + '-silent';
    notificationChannelKeyAudible = notificationChannelKey + '-audible';
  }

  ImmutableUploadManagerContext clone() {
    return new ImmutableUploadManagerContext (
      tusdServerUrl: this.tusdServerUrl,
      tusStoreDirectory: this.tusStoreDirectory,
      progressStoreFile:  this.progressStoreFile,
      notificationChannelKey: this.notificationChannelKey,
      notificationChannelGroupKey: this.notificationChannelGroupKey,
      notificationChannelName: this.notificationChannelName,
      notificationChannelGroupName: this.notificationChannelGroupName,
      notificationChannelDescription: this.notificationChannelDescription,
      notificationSoundSource: this.notificationSoundSource,
      notificationDefaultColor: this.notificationDefaultColor,
      notificationVibrationPattern: this.notificationVibrationPattern,
      tusdToken: this.tusdToken,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String,dynamic> map = {
      'tusd_server_url': tusdServerUrl.toString(),
      'tus_store_directory_path': tusStoreDirectory.path,
      'progress_store_file_path': progressStoreFile.path,
      'notification_channel_key': notificationChannelKey,
      'notification_channel_group_key': notificationChannelGroupKey,
      'notification_channel_name': notificationChannelName,
      'notification_channel_group_name': notificationChannelGroupName,
      'notification_channel_description': notificationChannelDescription,
      'notification_sound_source': notificationSoundSource,
      'notification_default_color': notificationDefaultColor?.value,
      'notification_vibration_pattern': notificationVibrationPattern?.toList(),
      'tusd_token': tusdToken,
    };

    // Remove keys with null values
    map.removeWhere((key, value) => value == null);
    return map;
  }

  static ImmutableUploadManagerContext toObject(Map<String, dynamic> input) {
    return new ImmutableUploadManagerContext(
      tusdServerUrl: Uri.parse(input['tusd_server_url']!),
      tusStoreDirectory: Directory(input['tus_store_directory_path']!),
      progressStoreFile: File(input['progress_store_file_path']!),
      notificationChannelKey: input['notification_channel_key']!,
      notificationChannelGroupKey: input['notification_channel_group_key']!,
      notificationChannelName: input['notification_channel_name'],
      notificationChannelGroupName: input['notification_channel_group_name'],
      notificationChannelDescription: input['notification_channel_description'],
      notificationSoundSource: input['notification_sound_source'],
      notificationDefaultColor: input['notification_default_color'] != null ? Color(input['notification_default_color']) : null,
      notificationVibrationPattern: input['notification_vibration_pattern'] != null ? Int64List.fromList(List<int>.from(input['notification_vibration_pattern'])) : null,
      tusdToken: input['tusd_token'],
    );
  }
}

typedef UploadContext = ImmutableUploadManagerContext;
