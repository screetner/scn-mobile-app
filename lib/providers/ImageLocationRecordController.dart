import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as path;
import 'package:tus_client_background_demo/services/LocationRecorder.dart';
import 'package:tus_client_background_demo/types/api/VideoSession.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../services/VideoSession.dart';
import '../services/models/SecureStorageCache.dart';
import '../types/ImmutableVideoRecordManagerContext.dart';

enum RecordState { STOPPED, RECORDING, PAUSED }

class ImageLocationRecordController {

  static bool _isInitialized = false;

  static late RecordContext _context;
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  late LocationRecorder _locationRecorder;

  static late Directory _recordDirectory;
  late Directory _sessionDirectory;
  String? _sessionStartTime;
  String? _currentVideoPath;
  String? _currentTlocPath;
  int _tlocRecordCount = 0;
  RandomAccessFile? _tlocWriteStream;

  List<String> allVideoFileName = [];
  List<int> allVideoRecordedTime = [];
  List<String> allTlocFileName = [];

  RecordState _recordState = RecordState.STOPPED;

  ImageLocationRecordController._privateConstructor();

  static Future<bool> initialize(RecordContext context) async {
    if(_isInitialized) {
      return false;
    }

    _context = context;

    _recordDirectory = _context.recordDirectory;
    if (!_recordDirectory.existsSync()) {
      _recordDirectory.createSync(recursive: true);
    }

    _isInitialized = true;

    return _isInitialized;
  }

  static Future<ImageLocationRecordController> createInstance() async {
    try {
      if (!_isInitialized) {
        throw Exception("ImageLocationRecordManager is not initialized.");
      }

      final locationRecordController = ImageLocationRecordController._privateConstructor();

      await Future.wait([
        locationRecordController._initializeCameras(),
        LocationRecorder.createInstance(locationRecordController._onLocationUpdate)
      ]).then((results) {
        locationRecordController._locationRecorder = results[1] as LocationRecorder;
      });

      return locationRecordController;
    }  catch (e, stackTrace) {
    // TODO: implement error handling
    print('An error occurred: $e');
    print('Stack trace: $stackTrace');
    throw e;
    }
  }

  void dispose() {
    if (_cameraController.value.isInitialized) {
      _cameraController.dispose();
    }

    _locationRecorder.dispose();
    _tlocWriteStream?.close();

    _recordState = RecordState.STOPPED;
  }

  Future<void> startRecording() async {
    try {
      print("STARTING RECORDING");
      if(!this.isStopped) {
        print("STARTING RECORDING FAILED");
        // Start recording must be called after stop recording state only
        return;
      }

      final now = DateTime.now();
      final nowUnix = now.millisecondsSinceEpoch;
      final nowISO = now.toUtc().toIso8601String();

      _sessionStartTime = nowISO;
      final sessionName = nowUnix.toString();
      _sessionDirectory = Directory(path.join(_recordDirectory.path, sessionName));
      if (!_sessionDirectory.existsSync()) {
        _sessionDirectory.createSync(recursive: true);
      }

      await _startNewVideoTlocRecord();
      _recordState = RecordState.RECORDING;
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> stopRecording() async {
    try {
      print("STOPPING RECORDING");
      print("RECORD STATE ${_recordState}");
      if(!this.isRecording && !this.isPausing) {
        print("STOPPING RECORDING FAILED");
        // Stop recording must be called after start recording or pause recording state only
        return;
      }

      final wasRecording = this.isRecording;
      _recordState = RecordState.STOPPED;
      if(wasRecording) {
        await _locationRecorder.stopLocationStream();
        await _stopVideoTlocRecord();
      }
      await _stopSession();

    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> resumeRecording() async {
    try {
      if(!this.isPausing) {
        // Resume recording must be called after pause recording state only
        return;
      }

      await _startNewVideoTlocRecord();
      _recordState = RecordState.RECORDING;
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> pauseRecording() async {
    try {
      if(!this.isRecording) {
        // Pause recording must be called after start recording state only
        return;
      }

      _recordState = RecordState.PAUSED;
      await _locationRecorder.stopLocationStream();
      //TODO: stop recording
      //await _cameraController.stopImageStream();
      await _stopVideoTlocRecord();
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> _startNewVideoTlocRecord() async {
    try {
      final now = DateTime.now();
      final nowUnix = now.millisecondsSinceEpoch;
      final videoFileName = '$nowUnix.mp4';
      final tlocFileName = '$nowUnix.tloc';

      _currentVideoPath = '${_sessionDirectory.path}/$videoFileName';
      _currentTlocPath = '${_sessionDirectory.path}/$tlocFileName';

      allVideoFileName.add(videoFileName);
      allVideoRecordedTime.add(nowUnix);
      allTlocFileName.add(tlocFileName);

      _tlocRecordCount = 0;
      _tlocWriteStream = await File(_currentTlocPath!).open(mode: FileMode.write);

      final zeroBytes = ByteData(4);
      await _tlocWriteStream!.writeFrom(zeroBytes.buffer.asUint8List());

      WakelockPlus.enable();
      await _locationRecorder.startLocationRecorder();
      await _cameraController.startVideoRecording();

    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> _stopVideoTlocRecord() async {
    try {
      WakelockPlus.disable();
      await _locationRecorder.stopLocationStream();
      final videoXFile = await _cameraController.stopVideoRecording();

      // Overwrite the first 4 bytes of the tloc file with _tlocRecordCount
      final byteData = ByteData(4)..setInt32(0, _tlocRecordCount, Endian.little);
      await _tlocWriteStream!.setPosition(0);
      await _tlocWriteStream!.writeFrom(byteData.buffer.asUint8List(), 0);
      await _tlocWriteStream!.close();


      // Move the video file to the session directory
      print("MOVING FILE FROM: ${videoXFile.path}");
      print("MOVING FILE AT");
      final MoveStartTime = DateTime.now().millisecondsSinceEpoch;
      await _moveFile(videoXFile.path, _currentVideoPath!);
      final MoveEndTime = DateTime.now().millisecondsSinceEpoch;
      print("FILE MOVED");
      print("TOTAL MOVING TIME: ${MoveEndTime - MoveStartTime}");
      print('Video recorded to ${_currentVideoPath}');
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> _stopSession() async {
    try {
      final infoMap = Map<String, dynamic>();

      final videoCount = allVideoFileName.length;

      final videpTlocTuples = <Map<String, dynamic>>[];
      for (int i = 0; i < videoCount; i++) {
        final videoTlocMap = <String, dynamic>{
          'videoName': allVideoFileName[i],
          'videoRecordedTime': allVideoRecordedTime[i],
          'tlocName': allTlocFileName[i],
        };
        videpTlocTuples.add(videoTlocMap);
      }

      final secureStorage = SecureStorageCache();
      final userId = await secureStorage.read(key: 'userId');

      infoMap['videoCount'] = videoCount;
      infoMap['sessionStartTime'] = _sessionStartTime;
      infoMap['recordedUserId'] = userId;
      infoMap['videoTlocTuples'] = videpTlocTuples;

      final infoFile = File('${_sessionDirectory.path}/information.json');
      final jsonString = jsonEncode(infoMap);
      await infoFile.writeAsString(jsonString, mode: FileMode.write, flush: true);

      _clearSessionData();

    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  void _clearSessionData() {
    allVideoFileName.clear();
    allVideoRecordedTime.clear();
    allTlocFileName.clear();
    _sessionStartTime = null;
  }

  Future<void> _moveFile(String fromPath, String toPath) async {
    final file = File(fromPath);
    await file.rename(toPath);
  }

  void _onLocationUpdate(Position position) {
    try {
      final latitude = position.latitude;
      final longitude = position.longitude;
      final timeUnix = position.timestamp.millisecondsSinceEpoch;

      final byteData = ByteData(24);
      byteData.setInt64(0, timeUnix, Endian.little);
      byteData.setFloat64(8, latitude, Endian.little);
      byteData.setFloat64(16, longitude, Endian.little);

      _tlocWriteStream!.writeFromSync(byteData.buffer.asUint8List());

      _tlocRecordCount++;
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await getAvailableCameras();
      _cameraController = CameraController(_cameras[0], ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _cameraController.initialize();

      await _cameraController.lockCaptureOrientation(DeviceOrientation.landscapeLeft);

    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<List<CameraDescription>> getAvailableCameras() async {
    return await availableCameras();
  }

  void _onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_cameraController == null) {
      return;
    }

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    _cameraController.setExposurePoint(offset);
    _cameraController.setFocusPoint(offset);
  }

  CameraController get cameraController => _cameraController;
  CameraPreview get cameraPreview => CameraPreview(_cameraController,
    // child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
    //   print('getting camera preview');
    //   return GestureDetector(
    //     behavior: HitTestBehavior.opaque,
    //     onTapDown: (details) =>
    //         _onViewFinderTap(details, constraints),
    //   );
    // })
  );
  RecordState get recordState => _recordState;

  bool get isRecording => _recordState == RecordState.RECORDING;
  bool get isPausing => _recordState == RecordState.PAUSED;
  bool get isStopped => _recordState == RecordState.STOPPED;
}

