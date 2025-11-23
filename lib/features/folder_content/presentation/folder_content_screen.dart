// lib/features/folder_content/screens/folder_content_screen.dart
import 'package:flutter/material.dart';
import 'package:locker/features/folder_content/presentation/widgets/media_grid.dart';
import 'package:locker/features/folder_content/presentation/widgets/media_picker_bottom_sheet.dart';
import 'package:provider/provider.dart';
import '../../home/models/home_category.dart';
import '../provider/media_provider.dart';

class FolderContentScreen extends StatefulWidget {
  final HomeCategory category;

  const FolderContentScreen({super.key, required this.category});

  @override
  State<FolderContentScreen> createState() => _FolderContentScreenState();
}

class _FolderContentScreenState extends State<FolderContentScreen> {
  @override
  void initState() {
    super.initState();
    // Load media after the widget is built and provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedia();
    });
  }

  void _loadMedia() {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    mediaProvider.loadMediaForFolder(widget.category.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: Colors.white70),
            onPressed: _showMediaPicker,
          ),
        ],
      ),
      body: Consumer<MediaProvider>(
        builder: (context, mediaProvider, child) {
          final mediaItems = mediaProvider.getMediaForFolder(widget.category.id);

          if (mediaProvider.mediaItems.isEmpty) {
            return _buildEmptyState();
          }

          return mediaItems.isEmpty
              ? _buildEmptyState()
              : MediaGrid(mediaItems: mediaItems);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMediaPicker,
        backgroundColor: widget.category.color,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.category.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.category.icon,
              size: 60,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'No ${widget.category.title.toLowerCase()} yet',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Tap + to add your first item',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaPickerBottomSheet(folderId: widget.category.id),
    );
  }
}