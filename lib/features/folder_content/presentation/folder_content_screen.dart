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
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

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

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  void _selectAll() {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final mediaItems = mediaProvider.getMediaForFolder(widget.category.id);
    setState(() {
      _selectedItems.clear();
      _selectedItems.addAll(mediaItems.map((item) => item.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedItems.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedItems.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E2E),
        title: Text('Delete Items', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${_selectedItems.length} item(s)?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      await mediaProvider.deleteMultipleMediaItems(
        _selectedItems.toList(),
        context,
      );

      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Items deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _restoreSelected() async {
    if (_selectedItems.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E2E),
        title: Text('Restore Items', style: TextStyle(color: Colors.white)),
        content: Text(
          'Restore ${_selectedItems.length} item(s) to gallery?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Restore', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      final results = await mediaProvider.restoreMultipleMediaItems(
        _selectedItems.toList(),
        context,
      );

      final successCount = results.where((r) => r).length;

      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount item(s) restored to gallery'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: _isSelectionMode 
            ? Color(0xFF1A1A2E)
            : Colors.transparent,
        elevation: _isSelectionMode ? 4 : 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: _isSelectionMode
              ? Text(
                  '${_selectedItems.length} selected',
                  key: ValueKey('selection'),
                  style: TextStyle(color: Colors.white, fontSize: 18),
                )
              : Consumer<MediaProvider>(
                  key: ValueKey('normal'),
                  builder: (context, mediaProvider, child) {
                    final itemCount = mediaProvider.getFolderItemCount(
                      widget.category.id,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          '$itemCount item${itemCount != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: _isSelectionMode
            ? [
                // Select All / Deselect All
                IconButton(
                  icon: Icon(
                    _selectedItems.length ==
                            Provider.of<MediaProvider>(
                              context,
                            ).getMediaForFolder(widget.category.id).length
                        ? Icons.deselect
                        : Icons.select_all,
                    color: Colors.white70,
                  ),
                  onPressed:
                      _selectedItems.length ==
                          Provider.of<MediaProvider>(
                            context,
                            listen: false,
                          ).getMediaForFolder(widget.category.id).length
                      ? _deselectAll
                      : _selectAll,
                ),
                // Restore
                IconButton(
                  icon: Icon(Icons.restore_rounded, color: Colors.green),
                  onPressed: _selectedItems.isEmpty ? null : _restoreSelected,
                ),
                // Delete
                IconButton(
                  icon: Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: _selectedItems.isEmpty ? null : _deleteSelected,
                ),
                // Cancel Selection
                IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: _toggleSelectionMode,
                ),
              ]
            : [
                // Selection Mode Toggle
                IconButton(
                  icon: Icon(Icons.checklist_rounded, color: Colors.white70),
                  onPressed: _toggleSelectionMode,
                ),
                // Add Media
                IconButton(
                  icon: Icon(Icons.add_rounded, color: Colors.white70),
                  onPressed: _showMediaPicker,
                ),
              ],
      ),
      body: Consumer<MediaProvider>(
        builder: (context, mediaProvider, child) {
          final mediaItems = mediaProvider.getMediaForFolder(
            widget.category.id,
          );

          if (mediaProvider.mediaItems.isEmpty) {
            return _buildEmptyState();
          }

          return mediaItems.isEmpty
              ? _buildEmptyState()
              : MediaGrid(
                  mediaItems: mediaItems,
                  isSelectionMode: _isSelectionMode,
                  selectedItems: _selectedItems,
                  onItemTap: _toggleItemSelection,
                );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
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
            child: Icon(widget.category.icon, size: 60, color: Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            'No ${widget.category.title.toLowerCase()} yet',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          SizedBox(height: 10),
          Text(
            'Tap + to add your first item',
            style: TextStyle(color: Colors.white38, fontSize: 14),
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
      builder: (context) =>
          MediaPickerBottomSheet(folderId: widget.category.id),
    );
  }
}
