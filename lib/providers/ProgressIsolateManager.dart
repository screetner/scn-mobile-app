import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'package:Screetner/services/models/ProgressFileStore.dart';

class ProgressIsolateManager {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  StreamSubscription? _subscription;
  bool _isRunning = false;

  Future<void> start(Directory progressUploadDirectory, void Function(Map<String, VideoSessionUploadProgress>) onProgressUpdate) async {
    if (_isRunning) return;
    _isRunning = true;

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort!.sendPort);

    Completer<void> completer = Completer();
    _subscription = _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        _sendPort!.send(progressUploadDirectory.path);
        completer.complete();
      } else if (message is Map<String, VideoSessionUploadProgress>) {
        onProgressUpdate(message);
      } else if (message is Map<String, String> && message.containsKey('error')) {
        print("Error: ${message['error']}");
      }
    });

    return completer.future;
  }

  void stop() {
    if (!_isRunning) return;
    _isRunning = false;

    _sendPort?.send('stop');
    _subscription?.cancel();
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
  }

  static Future<void> _isolateEntry(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    Timer? timer;

    await for (final message in receivePort) {
      if (message is String) {
        final progressUploadDirectory = Directory(message);
        final progressStore = ProgressFileStore(progressUploadDirectory);

        timer = Timer.periodic(Duration(seconds: 1), (timer) async {
          try {
            final progressMap = await progressStore.getAll();
            sendPort.send(progressMap);
          } catch (e) {
            sendPort.send({'error': 'Failed to read progress file: $e'});
          }
        });
      } else if (message == 'stop') {
        timer?.cancel();
        break;
      }
    }
  }
}
