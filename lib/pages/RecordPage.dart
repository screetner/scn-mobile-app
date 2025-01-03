
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tus_client_background_demo/providers/ImageLocationRecordController.dart';

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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100.0), // Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8.0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), // Padding inside the container
          child: Row(
            mainAxisSize: MainAxisSize.min, // Ensures the row only takes as much space as needed
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              if (_controller!.isStopped) ...[
                IconButton(
                  icon: const Icon(Icons.fiber_manual_record),
                  iconSize: 48.0,
                  color: Colors.red,
                  onPressed: _onVideoRecordButtonPressed,
                ),
              ] else if (_controller!.isRecording) ...[
                IconButton(
                  icon: const Icon(Icons.pause),
                  iconSize: 48.0,
                  color: Colors.black,
                  onPressed: _onPauseButtonPressed,
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  iconSize: 48.0,
                  color: Colors.black,
                  onPressed: _onStopButtonPressed,
                ),
              ] else if (_controller!.isPausing) ...[
                IconButton(
                  icon: const Icon(Icons.fiber_manual_record),
                  iconSize: 48.0,
                  color: Colors.red,
                  onPressed: _onResumeButtonPressed,
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  iconSize: 48.0,
                  color: Colors.black,
                  onPressed: _onStopButtonPressed,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  void _onPauseButtonPressed() {
    if (_controller!.isRecording) {
      _controller!.pauseRecording().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _onResumeButtonPressed() {
    if (_controller!.isPausing) {
      _controller!.resumeRecording().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _onStopButtonPressed() {
    _controller!.stopRecording().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onVideoRecordButtonPressed() {
    if (_controller!.isStopped) {
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