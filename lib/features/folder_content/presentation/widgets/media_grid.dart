// lib/features/folder_content/widgets/media_grid.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/media_item.dart';
import '../../provider/media_provider.dart';
import '../media_viewer_screen.dart';
class MediaGrid extends StatelessWidget {
  final List<MediaItem> mediaItems;

  const MediaGrid({super.key, required this.mediaItems});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        return MediaGridItem(mediaItem: mediaItems[index]);
      },
    );
  }
}

class MediaGridItem extends StatelessWidget {
  final MediaItem mediaItem;

  const MediaGridItem({super.key, required this.mediaItem});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openMediaViewer(context, mediaItem),
      onLongPress: () => _showDeleteDialog(context, mediaItem),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white10,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildMediaContent(),
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    switch (mediaItem.type) {
      case MediaType.image:
        return Image.file(
          File(mediaItem.filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorPlaceholder();
          },
        );
      case MediaType.video:
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildVideoThumbnail(),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ],
        );
      case MediaType.document:
        return _buildDocumentPlaceholder();
    }
  }

  Widget _buildVideoThumbnail() {
    // In a real app, you'd generate and cache thumbnails
    return Container(
      color: Colors.black26,
      child: Center(
        child: Icon(Icons.videocam_rounded,
            color: Colors.white70, size: 40),
      ),
    );
  }

  Widget _buildDocumentPlaceholder() {
    return Container(
      color: Colors.blueGrey.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_rounded,
                color: Colors.white70, size: 40),
            SizedBox(height: 4),
            Text(
              'DOC',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.red.withOpacity(0.1),
      child: Center(
        child: Icon(Icons.error_outline_rounded,
            color: Colors.white54, size: 32),
      ),
    );
  }

  void _openMediaViewer(BuildContext context, MediaItem mediaItem) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final mediaItems = mediaProvider.mediaItems;
    final initialIndex = mediaItems.indexOf(mediaItem);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(
          mediaItems: mediaItems,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MediaItem mediaItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E2E),
        title: Text(
          'Delete Media',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this ${mediaItem.type.name}?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMedia(context, mediaItem);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

// In lib/features/folder_content/widgets/media_grid.dart - Update the delete method
  Future<void> _deleteMedia(BuildContext context, MediaItem mediaItem) async {
    try {
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      await mediaProvider.deleteMediaItem(mediaItem.id, context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Media deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete media'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}