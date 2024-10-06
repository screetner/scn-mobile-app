import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'package:tus_client_background_demo/services/models/ProgressFileStore.dart';

class ProgressIsolateManager {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  StreamSubscription? _subscription;
  bool _isRunning = false;

  Future<void> start(File progressFile, void Function(Map<String, double>) onProgressUpdate) async {
    if (_isRunning) return;
    _isRunning = true;

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort!.sendPort);

    Completer<void> completer = Completer();
    _subscription = _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        _sendPort!.send(progressFile.path);
        completer.complete();
      } else if (message is Map<String, double>) {
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
        final progressFile = File(message);
        final progressStore = ProgressFileStore(progressFile);

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
