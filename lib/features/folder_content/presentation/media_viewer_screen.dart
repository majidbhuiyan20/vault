// lib/features/folder_content/screens/media_viewer_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:locker/features/folder_content/presentation/widgets/custom_video_player.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
                  child: Icon(
                    Icons.error_rounded,
                    color: Colors.white54,
                    size: 64,
                  ),
                );
              },
            ),
          ),
        );
      case MediaType.video:
        return CustomVideoPlayer(videoPath: mediaItem.filePath);
      case MediaType.document:
        return Center(
          child: Icon(
            Icons.description_rounded,
            color: Colors.white54,
            size: 64,
          ),
        );
    }
  }

  Widget _buildBottomInfo() {
    final mediaItem = widget.mediaItems[_currentIndex];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
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
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _getMediaIcon(mediaItem.type),
                color: Colors.white70,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                _getMediaInfo(mediaItem),
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getMediaIcon(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Icons.photo_rounded;
      case MediaType.video:
        return Icons.videocam_rounded;
      case MediaType.document:
        return Icons.description_rounded;
    }
  }

  String _getMediaInfo(MediaItem mediaItem) {
    final date =
        '${mediaItem.createdDate.day}/${mediaItem.createdDate.month}/${mediaItem.createdDate.year}';

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
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
