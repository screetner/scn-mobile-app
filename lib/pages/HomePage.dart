import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tus_client_background_demo/presentations/ScreetnerMainApp.dart';
import 'package:tus_client_background_demo/providers/DirectoryUploadManager.dart';
import 'package:tus_client_background_demo/providers/VideoMetadataProvider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  late Future<List<VideoInfo>> _videoInfoList;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final route = ModalRoute.of(context)!;
      if (route is PageRoute) {
        ScreetnerMainApp.routeObserver.subscribe(this, route);
      }
    });

    _loadVideoInfo();
  }

  @override
  void dispose() {
    ScreetnerMainApp.routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _loadVideoInfo() {
    _videoInfoList = VideoMetadataProvider().getVideoInfo();
  }

  @override
  void didPopNext() {
    setState(() {
      _loadVideoInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<List<VideoInfo>>(
        future: _videoInfoList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No files found'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildVideoCard(context, items[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, VideoInfo videoInfo) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildThumbnail(videoInfo.thumbnail),
        title: Text(
          videoInfo.sessionTitle ?? "Untitled",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${videoInfo.frameCount.toString()} frames',
          style: const TextStyle(color: Colors.grey),
        ),
        onTap: () {
          DirectoryUploadManager().uploadDirectory(uploadDirectory: videoInfo.sessionDirectory);
          // Handle tap event
        },
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
}
