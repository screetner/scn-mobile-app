import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';

import '../types/ImmutableUploadManagerContext.dart';

class NotificationManager {
  bool _isInitialized = false;

  final Map<String, int> _notificationIdMap = {};

  late UploadContext _context;

  NotificationManager._privateConstructor();

  static final NotificationManager _instance = NotificationManager._privateConstructor();

  NotificationManager._withContext(UploadContext context) {
    _context = context.clone();
  }

  factory NotificationManager() {
    return _instance;
  }

  Future<bool> initialize(UploadContext context) async {
    if(_isInitialized) {
      return false;
    }

    _context = context.clone();

    String notificationChannelName = _context.notificationChannelName ?? _context.notificationChannelKey;
    String notificationChannelGroupName = _context.notificationChannelGroupName ?? _context.notificationChannelGroupKey;
    String notificationChannelDescription = _context.notificationChannelDescription ??
        "NotificationPage.dart channel for reporting file upload progress";

    bool notificationsInitialized = await AwesomeNotifications().initialize(
      null, // default icon
      [
        NotificationChannel(
          channelGroupKey: _context.notificationChannelGroupKey,
          channelKey: _context.notificationChannelKeySilent,
          channelName: notificationChannelName,
          channelDescription: notificationChannelDescription,
          defaultColor: _context.notificationDefaultColor,
          soundSource: _context.notificationSoundSource,
          playSound: false,
          enableVibration: false,
          vibrationPattern: _context.notificationVibrationPattern,
        ),
        NotificationChannel(
          channelGroupKey: _context.notificationChannelGroupKey,
          channelKey: _context.notificationChannelKeyAudible,
          channelName: notificationChannelName,
          channelDescription: notificationChannelDescription,
          defaultColor: _context.notificationDefaultColor,
          soundSource: _context.notificationSoundSource,
          playSound: true,
          enableVibration: true,
          vibrationPattern: _context.notificationVibrationPattern,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: _context.notificationChannelGroupKey,
          channelGroupName: notificationChannelGroupName,
        ),
      ],
    );

    _isInitialized = notificationsInitialized;
    return notificationsInitialized;
  }

  static Future<NotificationManager> buildInstance(UploadContext context) async {
    final nm = NotificationManager._withContext(context);
    await nm.initialize(context);
    return nm;
  }

  // credits to awesome-notification documentation
  // link: https://awesome-notification-docs.vercel.app/
  void updateProgressBarFor(String fingerprint, double progressPercentage) {
    const double maxPercentage = 100;

    final id = getNotificationIdFor(fingerprint);
    final fileName = fingerprint.split('/').last;

    print("PROGRESS PERCENTAGE: $progressPercentage");

    if (progressPercentage < maxPercentage) {
      double progress = min(progressPercentage, maxPercentage);
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _context.notificationChannelKeySilent,
          groupKey: _context.notificationChannelGroupKey,
          title: 'Uploading ${fileName} ${progress.toInt()}%',
          body: 'fanum tax',
          category: NotificationCategory.Progress,
          notificationLayout: NotificationLayout.ProgressBar,
          progress: progress,
          locked: true,
        ),
      );
    } else {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _context.notificationChannelKeyAudible,
          groupKey: _context.notificationChannelGroupKey,
          title: 'Upload ${fileName} finished',
          body: 'skibidi',
          category: NotificationCategory.Progress,
          notificationLayout: NotificationLayout.Default,
          locked: false,
        ),
      );
    }
  }

  int getNotificationIdFor(String key) {
    if (_notificationIdMap.containsKey(key)) {
      return _notificationIdMap[key]!;
    }

    int hashCode = key.hashCode;
    while(_notificationIdMap.containsValue(hashCode)) { hashCode++; }
    _notificationIdMap[key] = hashCode;

    return hashCode;
  }

  int? removeNotificationIdFor(String key) {
    return _notificationIdMap.remove(key);
  }
}