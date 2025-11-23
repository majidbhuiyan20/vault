// lib/features/folder_content/widgets/media_grid.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/media_item.dart';
import '../../provider/media_provider.dart';
import '../media_viewer_screen.dart';

class MediaGrid extends StatelessWidget {
  final List<MediaItem> mediaItems;
  final bool isSelectionMode;
  final Set<String> selectedItems;
  final Function(String)? onItemTap;

  const MediaGrid({
    super.key,
    required this.mediaItems,
    this.isSelectionMode = false,
    this.selectedItems = const {},
    this.onItemTap,
  });

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
        return MediaGridItem(
          mediaItem: mediaItems[index],
          isSelectionMode: isSelectionMode,
          isSelected: selectedItems.contains(mediaItems[index].id),
          onSelectionTap: onItemTap,
        );
      },
    );
  }
}

class MediaGridItem extends StatelessWidget {
  final MediaItem mediaItem;
  final bool isSelectionMode;
  final bool isSelected;
  final Function(String)? onSelectionTap;

  const MediaGridItem({
    super.key,
    required this.mediaItem,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isSelectionMode && onSelectionTap != null) {
          onSelectionTap!(mediaItem.id);
        } else {
          _openMediaViewer(context, mediaItem);
        }
      },
      onLongPress: isSelectionMode
          ? null
          : () => _showDeleteDialog(context, mediaItem),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white10,
              border: isSelected
                  ? Border.all(color: Colors.blue, width: 3)
                  : null,
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
          // Selection indicator
          if (isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue
                      : Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.white,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
        ],
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
            // Play button overlay
            Center(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            // Duration badge
            if (mediaItem.duration != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(mediaItem.duration!),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        );
      case MediaType.document:
        return _buildDocumentPlaceholder();
    }
  }

  Widget _buildVideoThumbnail() {
    // Show generated thumbnail if available
    if (mediaItem.thumbnailPath != null &&
        File(mediaItem.thumbnailPath!).existsSync()) {
      return Image.file(
        File(mediaItem.thumbnailPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildVideoPlaceholder();
        },
      );
    }

    return _buildVideoPlaceholder();
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1E2E), Color(0xFF2A2A3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.videocam_rounded, color: Colors.white54, size: 40),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildDocumentPlaceholder() {
    return Container(
      color: Colors.blueGrey.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_rounded, color: Colors.white70, size: 40),
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
        child: Icon(
          Icons.error_outline_rounded,
          color: Colors.white54,
          size: 32,
        ),
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
        title: Text('Delete Media', style: TextStyle(color: Colors.white)),
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
