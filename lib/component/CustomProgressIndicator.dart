import 'package:flutter/material.dart';

import '../services/models/ProgressFileStore.dart';

class CustomProgressIndicator extends StatefulWidget {
  const CustomProgressIndicator({
    super.key,
    required this.uploadProgress,
  });

  final VideoSessionUploadProgress uploadProgress;

  @override
  State<CustomProgressIndicator> createState() => _CustomProgressIndicatorState();
}

class _CustomProgressIndicatorState extends State<CustomProgressIndicator> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
      if (widget.uploadProgress.uploadState == VideoSessionUploadStateEnum.REQUESTING_UPLOAD) {
        setState(() {});
      }
    });

    _startAnimationIfRequired();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CustomProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uploadProgress.uploadState != oldWidget.uploadProgress.uploadState) {
      _startAnimationIfRequired();
    }
  }

  void _startAnimationIfRequired() {
    if (widget.uploadProgress.uploadState == VideoSessionUploadStateEnum.REQUESTING_UPLOAD) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: widget.uploadProgress.uploadState == VideoSessionUploadStateEnum.REQUESTING_UPLOAD ?
        LinearProgressIndicator() :
        LinearProgressIndicator(value: widget.uploadProgress.progress / 100)
    );
  }
}
