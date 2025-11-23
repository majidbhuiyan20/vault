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
      padding: EdgeInsets.all(12),
      physics: BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.75,
      ),
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: MediaGridItem(
            key: ValueKey(mediaItems[index].id),
            mediaItem: mediaItems[index],
            isSelectionMode: isSelectionMode,
            isSelected: selectedItems.contains(mediaItems[index].id),
            onSelectionTap: onItemTap,
          ),
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
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.05),
          border: isSelected
              ? Border.all(color: Color(0xFF4361EE), width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Media content
              Positioned.fill(
                child: _buildMediaContent(),
              ),
              
              // Gradient overlay for better text visibility
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Selection indicator
              if (isSelectionMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFF4361EE)
                          : Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Color(0xFF4361EE) : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
              
              // File type indicator
              if (!isSelectionMode)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mediaItem.type == MediaType.video
                              ? Icons.videocam_rounded
                              : Icons.image_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        if (mediaItem.type == MediaType.video &&
                            mediaItem.duration != null) ...[
                          SizedBox(width: 4),
                          Text(
                            _formatDuration(mediaItem.duration!),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
            // Play button overlay
            Center(
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
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
