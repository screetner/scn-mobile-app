
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tus_client_background_demo/providers/ImageLocationRecordController.dart';

// TODO: uncomment this
// import 'package:wakelock/wakelock.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<StatefulWidget> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  List<CameraDescription>? _cameras;

  XFile? videoFile;

  String? _recordStartTime;

  late Directory appDirectory;
  late String videoDirectoryPath;

  ImageLocationRecordController? _controller;

  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _initializeImageLocationRecordController();
  }

  @override
  void dispose() {
    if(_controller != null) {
      _controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(_controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
        body: Stack(
          children: <Widget>[
            _cameraPreviewWidget(),
            _captureControlRowWidget()
          ],
        )
    );
  }

  Widget _cameraPreviewWidget() {
    // credits to Adam Vidarsson on Medium
    // link: https://medium.com/lightsnap/making-a-full-screen-camera-application-in-flutter-65db7f5d717b

    final mediaSize = MediaQuery.of(context).size;
    final scale = 1 / (_controller!.cameraController.value.aspectRatio * mediaSize.aspectRatio);

    final clipper = _MediaSizeClipper(mediaSize);

    return ClipRect(
      clipper: clipper,
      child: Container(
        color: Colors.black,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: RotatedBox(quarterTurns: 1, child: _controller!.cameraPreview),
        ),
      ),
    );
  }

  Widget _captureControlRowWidget() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.videocam),
              iconSize: 48.0,
              color: (_controller!.isRecording) ? Colors.red : Colors.blue,
              onPressed: _onVideoRecordButtonPressed,
            ),
          ],
        ),
      ),
    );
  }

  void _onVideoRecordButtonPressed() {
    if(_controller!.isRecording) {
      // TODO: disable wakelock
      _controller!.stopRecording().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      // TODO: uncomment this
      // Wakelock.enable();
      _controller!.startRecording().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  Future<void> _initializeImageLocationRecordController() async {
    try {
      final instance = await ImageLocationRecordController.createInstance();
      final cameras = await instance.getAvailableCameras();
      setState(() {
        _controller = instance;
        _cameras = cameras;
      });
    } catch (e) {
      print('Initialization error: $e');
    }
  }
}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }
  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}