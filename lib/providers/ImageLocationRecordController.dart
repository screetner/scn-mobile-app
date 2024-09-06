import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as imglib;
import 'package:path/path.dart' as path;
import 'package:tus_client_background_demo/services/LocationRecorder.dart';

import '../types/ImmutableVideoRecordManagerContext.dart';

enum RecordState { STOPPED, RECORDING, PAUSED }

class ImageLocationRecordController {

  static bool _isInitialized = false;

  static late RecordContext _context;
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  late LocationRecorder _locationRecorder;

  static late Directory _recordDirectory;
  late Directory _currentDirectory;
  late Directory _frameInfoDirectory;
  late int _recordIntervalMilliseconds;

  Map<String, dynamic> _currentRecordInformation = new Map();
  RecordState _recordState = RecordState.STOPPED;
  int _frameCount = 0;

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

      await locationRecordController._initializeCameras();
      locationRecordController._locationRecorder = await LocationRecorder.createInstance();
      locationRecordController._recordIntervalMilliseconds = _context.recordIntervalMilliseconds;

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

    _recordState = RecordState.STOPPED;
    _frameCount = 0;
    _currentRecordInformation.clear();
  }


  Future<void> startRecording() async {
    try {
      reset();

      final now = DateTime.now();
      final nowUnix = now.millisecondsSinceEpoch;
      final nowISO = now.toIso8601String();

      _currentDirectory = Directory(path.join(_recordDirectory.path, nowUnix.toString()));
      if (!_currentDirectory.existsSync()) {
        _currentDirectory.createSync(recursive: true);
      }

      _frameInfoDirectory =Directory(path.join(_recordDirectory.path, '${nowUnix.toString()}_info'));
      if (!_frameInfoDirectory.existsSync()) {
        _frameInfoDirectory.createSync(recursive: true);
      }

      _recordState = RecordState.RECORDING;

      _currentRecordInformation['recordedTime'] = nowISO;
      _currentRecordInformation['recordIntervalMilliseconds'] = _recordIntervalMilliseconds;

      final recordIntervalDuration = Duration(milliseconds: _recordIntervalMilliseconds);
      await _locationRecorder.startLocationRecorder();
      await _cameraController.startImageStream(_throttle(this._processImage, recordIntervalDuration));

    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> stopRecording() async {
    try {
      _recordState = RecordState.STOPPED;
      await _locationRecorder.stopLocationStream();
      await _cameraController.stopImageStream();

      _currentRecordInformation['frameCount'] = _frameCount;

      String jsonString = jsonEncode(_currentRecordInformation);
      final File infoFile = File('${_currentDirectory.path}/information.json');
      await infoFile.writeAsString(jsonString);

    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> pauseRecording() async {
    try {
      _recordState = RecordState.PAUSED;
      await _locationRecorder.stopLocationStream();
      _cameraController.stopImageStream();
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> resumeRecording() async {
    try {
      _recordState = RecordState.RECORDING;

      final recordIntervalDuration = Duration(milliseconds: _recordIntervalMilliseconds);
      await _locationRecorder.startLocationRecorder();
      await _cameraController.startImageStream(_throttle(this._processImage, recordIntervalDuration));
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  void reset() {
    _frameCount = -1;
    _currentRecordInformation.clear();
  }

  Future<void> _processImage(CameraImage image) async {
    try {
      _frameCount++;

      print("frame number: ${_frameCount}");

      final nowUnix = DateTime.now().millisecondsSinceEpoch;
      // Position position = await _locationRecorder.getCurrentLocation();
      Position position = await _locationRecorder.position;

      // final jpegImage = await _convertImageToJpeg(image);
      final yuvImage = await _convertImageToYUV(image);

      final String fileName = 'frame_$_frameCount';
      final String destinationPath = path.join(_currentDirectory.path, fileName) + '.yuv';
      final String infoDestinationPath = path.join(_frameInfoDirectory.path, fileName);

      final File jpegFile = File(destinationPath);
      await jpegFile.writeAsBytes(yuvImage);

      final File infoFile = File(infoDestinationPath);
      await _writeInfoFile(infoFile, position, nowUnix);


      if(_frameCount == 1) {
        _currentRecordInformation['firstFrameName'] = fileName;
      }
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> _writeInfoFile(File file, Position position, int timeUnix) async {
    try {
      ByteData byteData = ByteData(24);
      byteData.setFloat64(0, position.latitude, Endian.little);
      byteData.setFloat64(8, position.longitude, Endian.little);
      byteData.setInt64(16, timeUnix, Endian.little);

      await file.writeAsBytes(byteData.buffer.asUint8List());
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<Map<String, dynamic>> readInfoFile(File file) async {
    try {
      final Uint8List fileBytes = await file.readAsBytes();
      final ByteData byteData = ByteData.sublistView(fileBytes);

      final double latitude = byteData.getFloat64(0, Endian.little);
      final double longitude = byteData.getFloat64(8, Endian.little);
      final int timeUnixMillis = byteData.getInt64(16, Endian.little);

      return {
        'latitude': latitude,
        'longitude': longitude,
        'timeUnix': timeUnixMillis,
      };
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<Uint8List> _convertImageToYUV(CameraImage image) async {
    // Extract the Y, U, and V planes
    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    // Ensure the planes are in the correct order: Y, U, V
    // The YUV420 format contains the Y plane followed by U and V (subsampled).
    List<int> yuvData = [];

    // Add Y plane data
    yuvData.addAll(yPlane);

    // Add U plane data
    yuvData.addAll(uPlane);

    // Add V plane data
    yuvData.addAll(vPlane);

    // Convert the list to a Uint8List to write to the file
    Uint8List yuvBytes = Uint8List.fromList(yuvData);
    return yuvBytes;
  }

  // Credits to faslurrajah on GitHub
  // Link: https://github.com/flutter/flutter/issues/26348#issuecomment-1600644862
  Future<Uint8List> _convertImageToJpeg(CameraImage image) async {
    try {
      Uint8List bytes;
      imglib.Image img;
      if (image.format.group == ImageFormatGroup.yuv420) {
        img = await _convertYUV420(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        img = await _convertBGRA8888(image);
      } else {
        throw Exception("The using image format is not supported");
      }

      bytes = imglib.encodeJpg(img);
      return bytes;
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<imglib.Image> _convertBGRA8888(CameraImage image) async {
    try {
      return imglib.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: image.planes[0].bytes.buffer,
        order: imglib.ChannelOrder.bgra,
      );
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<imglib.Image> _convertYUV420(CameraImage image) async {
    try {
      // credits to krzaklus
      // https://gist.github.com/Alby-o/fe87e35bc21d534c8220aed7df028e03?permalink_comment_id=4555000#gistcomment-4555000
      print("image process start");
      final imageWidth = image.width;
      final imageHeight = image.height;

      final yBuffer = image.planes[0].bytes;
      final uBuffer = image.planes[1].bytes;
      final vBuffer = image.planes[2].bytes;

      final int yRowStride = image.planes[0].bytesPerRow;
      final int yPixelStride = image.planes[0].bytesPerPixel!;

      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel!;

      final img = imglib.Image(width: imageWidth, height: imageHeight);

      for (int h = 0; h < imageHeight; h++) {
        int uvh = (h / 2).floor();

        for (int w = 0; w < imageWidth; w++) {
          int uvw = (w / 2).floor();

          final yIndex = (h * yRowStride) + (w * yPixelStride);

          // Y plane should have positive values belonging to [0...255]
          final int y = yBuffer[yIndex];

          // U/V Values are subsampled i.e. each pixel in U/V chanel in a
          // YUV_420 image act as chroma value for 4 neighbouring pixels
          final int uvIndex = (uvh * uvRowStride) + (uvw * uvPixelStride);

          // U/V values ideally fall under [-0.5, 0.5] range. To fit them into
          // [0, 255] range they are scaled up and centered to 128.
          // Operation below brings U/V values to [-128, 127].
          final int u = uBuffer[uvIndex];
          final int v = vBuffer[uvIndex];

          // Compute RGB values per formula above.
          int r = (y + v * 1436 / 1024 - 179).round();
          int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
          int b = (y + u * 1814 / 1024 - 227).round();

          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          img.setPixelRgb(w, h, r, g, b);
        }
      }

      final rotatedImage = imglib.copyRotate(img, angle: 270);

      print("image processed");
      return rotatedImage;
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
      _cameraController = CameraController(_cameras[0], ResolutionPreset.max,
        fps: 1,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _cameraController.initialize();

    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> Function(CameraImage image) _throttle(Future<void> Function(CameraImage image) callback, Duration duration) {
    DateTime lastExecution = DateTime.fromMillisecondsSinceEpoch(0);
    return (CameraImage image) async {
      final now = DateTime.now();
      if (now.difference(lastExecution) >= duration) {
        lastExecution = now;
        await callback(image);
      }
    };
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
    child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      print('getting camera preview');
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) =>
            _onViewFinderTap(details, constraints),
      );
    })
  );
  RecordState get recordState => _recordState;

  bool get isRecording => _recordState == RecordState.RECORDING;
  bool get isPausing => _recordState == RecordState.PAUSED;
  bool get isPaused => _recordState == RecordState.STOPPED;
}

