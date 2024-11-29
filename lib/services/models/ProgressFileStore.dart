import 'dart:io';
import 'dart:convert';
import 'package:synchronized/synchronized.dart';

abstract class ProgressStore {
  Future<void> set(String fingerprint, double progress);

  Future<double?> get(String fingerprint);

  Future<void> remove(String fingerprint);

  Future<Map<String, double>> getAll();
}

class ProgressFileStore implements ProgressStore {
  ProgressFileStore(this.file);

  final File file;
  Map<String, double> _progressMap = {};
  final _lock = Lock();

  Future<void> _loadFromFile() async {
    await _lock.synchronized(() async {
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> jsonMap = jsonDecode(contents);
        _progressMap = jsonMap.map((key, value) => MapEntry(key, value.toDouble()));
      }
    });
  }


  Future<void> _saveToFile() async {
    await _lock.synchronized(() async {
      final jsonMap = _progressMap.map((key, value) => MapEntry(key, value));
      final contents = jsonEncode(jsonMap);
      await file.writeAsString(contents, mode: FileMode.writeOnly, flush: true);
    });
  }

  @override
  Future<void> set(String fingerprint, double progress) async {
    await _loadFromFile();
    _progressMap[fingerprint] = progress;
    await _saveToFile();
  }

  @override
  Future<double?> get(String fingerprint) async {
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
  Future<Map<String, double>> getAll() async {
    await _loadFromFile();
    return _progressMap;
  }
}