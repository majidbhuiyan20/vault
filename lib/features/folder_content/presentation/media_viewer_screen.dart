// lib/features/folder_content/screens/media_viewer_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';

class MediaViewerScreen extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final int initialIndex;

  const MediaViewerScreen({
    super.key,
    required this.mediaItems,
    required this.initialIndex,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideoIfNeeded();
  }

  void _initializeVideoIfNeeded() {
    final currentMedia = widget.mediaItems[_currentIndex];
    if (currentMedia.type == MediaType.video) {
      _initializeVideoPlayer(currentMedia.filePath);
    }
  }

  void _initializeVideoPlayer(String videoPath) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(videoPath))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.mediaItems.length}',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_videoController != null) _buildVideoControls(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.mediaItems.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _videoController?.dispose();
                    _videoController = null;
                    _initializeVideoIfNeeded();
                  });
                },
                itemBuilder: (context, index) {
                  final mediaItem = widget.mediaItems[index];
                  return _buildMediaContent(mediaItem);
                },
              ),
            ),
            _buildBottomInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(MediaItem mediaItem) {
    switch (mediaItem.type) {
      case MediaType.image:
        return InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 3.0,
          child: Center(
            child: Image.file(
              File(mediaItem.filePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(Icons.error_rounded,
                      color: Colors.white54, size: 64),
                );
              },
            ),
          ),
        );
      case MediaType.video:
        return _buildVideoPlayer();
      case MediaType.document:
        return Center(
          child: Icon(Icons.description_rounded,
              color: Colors.white54, size: 64),
        );
    }
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  Widget _buildVideoControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _videoController!.value.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildBottomInfo() {
    final mediaItem = widget.mediaItems[_currentIndex];

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mediaItem.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            _getMediaInfo(mediaItem),
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getMediaInfo(MediaItem mediaItem) {
    final date = '${mediaItem.createdDate.day}/${mediaItem.createdDate.month}/${mediaItem.createdDate.year}';

    switch (mediaItem.type) {
      case MediaType.image:
        return 'Image • $date';
      case MediaType.video:
        final duration = mediaItem.duration != null
            ? ' • ${_formatDuration(mediaItem.duration!)}'
            : '';
        return 'Video • $date$duration';
      case MediaType.document:
        return 'Document • $date';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inMinutes}:$seconds';
  }
}