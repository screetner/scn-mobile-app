import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tus_client_background_demo/presentations/ScreetnerMainApp.dart';
import 'package:tus_client_background_demo/providers/DirectoryUploadManager.dart';
import 'package:tus_client_background_demo/providers/ErrorAsserter.dart';
import 'package:tus_client_background_demo/providers/ProgressIsolateManager.dart';
import 'package:tus_client_background_demo/providers/VideoMetadataProvider.dart';

import '../component/CustomProgressIndicator.dart';
import '../services/models/ProgressFileStore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late Future<List<VideoInfo>> _videoInfoListFuture;
  late List<VideoInfo> _videoInfoList;
  final Set<VideoInfo> _expandedCards = {};
  final Map<String, VideoSessionUploadProgress> _uploadProgressMap = {};
  late ProgressIsolateManager _progressIsolateManager;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final route = ModalRoute.of(context)!;
      if (route is PageRoute) {
        ScreetnerMainApp.routeObserver.subscribe(this, route);
      }
    });

    _videoInfoListFuture = _loadVideoInfo();
    _progressIsolateManager = ProgressIsolateManager();
    _startProgressIsolate();
  }

  @override
  void dispose() {
    ScreetnerMainApp.routeObserver.unsubscribe(this);
    _progressIsolateManager.stop();
    super.dispose();
  }

  Future<List<VideoInfo>> _loadVideoInfo() async {
    return await VideoMetadataProvider().getVideoInfo();
  }

  Future<void> _startProgressIsolate() async {
    final context = DirectoryUploadManager().getContext();
    final progressFile = context.progressStoreFile;

    await _progressIsolateManager.start(progressFile, (progressMap) {
      setState(() {
        _uploadProgressMap.addAll(progressMap);
      });
    });
  }

  @override
  void didPopNext() {
    setState(() {
      _videoInfoListFuture = _loadVideoInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<List<VideoInfo>>(
          future: _videoInfoListFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No videos found'));
            }

            _videoInfoList = snapshot.data!;
            return AnimatedList(
              key: _listKey,
              initialItemCount: _videoInfoList.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, index, animation) {
                final videoInfo = _videoInfoList[index];
                return _buildVideoCard(context, videoInfo, animation);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, VideoInfo videoInfo, Animation<double> animation) {
    final expansionStyle = AnimationStyle(
      curve: Easing.standard,
      duration: Durations.short2,
    );

    final uploadButton = Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () {
            Asserter().handle(context, () {
              DirectoryUploadManager().uploadDirectory(uploadDirectory: videoInfo.sessionDirectory);
            });
          },
          child: Icon(Icons.cloud_upload),
        ),
      ),
    );

    final deleteButton = Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () {
            Asserter().handle(context, () {
              _showDeleteConfirmationDialog(context, videoInfo);
            });
          },
          child: Icon(Icons.delete_outline, color: Colors.red),
        ),
      ),
    );

    final sessionDirectoryPath = videoInfo.sessionDirectory.path;
    final baseUP = VideoSessionUploadProgress(progress: 0.0, uploadState: VideoSessionUploadStateEnum.UNUPLOADED);
    final currentUP = _uploadProgressMap[sessionDirectoryPath];
    final actualUP = currentUP ?? baseUP;

    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CustomProgressIndicator(uploadProgress: actualUP),
            ExpansionTile(
              key: PageStorageKey<VideoInfo>(videoInfo),
              leading: _buildThumbnail(videoInfo.thumbnail),
              title: Text(
                videoInfo.sessionTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: <Widget>[
                Flex(
                  direction: Axis.horizontal,
                  children: [
                    uploadButton,
                    deleteButton,
                  ],
                ),
              ],
              expansionAnimationStyle: expansionStyle,
              dense: false,
              initiallyExpanded: _expandedCards.contains(videoInfo),
              onExpansionChanged: (bool expanded) {
                setState(() {
                  if (expanded) {
                    _expandedCards.add(videoInfo);
                  } else {
                    _expandedCards.remove(videoInfo);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(Uint8List? thumbnailData) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        image: thumbnailData != null
            ? DecorationImage(
          image: MemoryImage(thumbnailData),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: thumbnailData == null
          ? Icon(
        Icons.video_library,
        size: 50,
        color: Colors.greenAccent,
      )
          : null,
    );
  }

  void _removeItem(VideoInfo videoInfo) {
    final index = _videoInfoList.indexOf(videoInfo);
    final removedItem = _videoInfoList.removeAt(index);
    _expandedCards.remove(videoInfo);
    _listKey.currentState!.removeItem(
      index,
          (context, animation) => _buildRemovedItem(context, removedItem, animation),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildRemovedItem(BuildContext context, VideoInfo videoInfo, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: _buildVideoCard(context, videoInfo, animation),
      ),
    );
  }

  void _showDeleteNotification(BuildContext context) {
    final snackBar = SnackBar(
      content: Text('The card has been successfully deleted.'),
      backgroundColor: Colors.redAccent,
      duration: Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, VideoInfo videoInfo) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this card?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                DirectoryUploadManager().deleteDirectory(deleteDirectory: videoInfo.sessionDirectory);
                _removeItem(videoInfo);
                _showDeleteNotification(context);
              },
            ),
          ],
        );
      },
    );
  }
}