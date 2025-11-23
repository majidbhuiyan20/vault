// lib/features/folder_content/widgets/media_picker_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/media_provider.dart';

class MediaPickerBottomSheet extends StatelessWidget {
  final String folderId;

  const MediaPickerBottomSheet({super.key, required this.folderId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Add Media',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Files will be secured & hidden from gallery',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: Colors.white24, height: 1),

            // Options
            _buildOptionTile(
              context,
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Select images (copies)',
              onTap: () => _pickFromGallery(context),
            ),

            _buildOptionTile(
              context,
              icon: Icons.collections_rounded,
              title: 'Choose Multiple Media',
              subtitle: 'Select & remove from gallery',
              onTap: () => _pickMultipleMedia(context),
            ),

            _buildOptionTile(
              context,
              icon: Icons.video_library_rounded,
              title: 'Choose Video',
              subtitle: 'Select videos (copies)',
              onTap: () => _pickVideo(context),
            ),

            _buildOptionTile(
              context,
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              subtitle: 'Capture a new photo',
              onTap: () => _takePhoto(context),
            ),

            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70),
      ),
      title: Text(title, style: TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white54)),
      onTap: onTap,
    );
  }

  void _pickFromGallery(BuildContext context) async {
    // Get provider reference before closing dialog
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Navigator.pop(context);

    try {
      await mediaProvider.addImageFromGallery(folderId, context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Image secured successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to add image'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _pickMultipleMedia(BuildContext context) async {
    // Get provider reference before closing dialog
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Navigator.pop(context);

    try {
      // Show inline snackbar notification instead of blocking dialog
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text('Securing & hiding media files...'),
              ),
            ],
          ),
          duration: Duration(hours: 1), // Keep visible during processing
          backgroundColor: Color(0xFF4361EE),
        ),
      );

      final count = await mediaProvider.addMultipleMediaWithDeletion(folderId, context);
      
      // Hide the progress snackbar
      scaffoldMessenger.hideCurrentSnackBar();
      
      if (count > 0) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count file${count > 1 ? 's' : ''} secured!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Secured & removed from gallery',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('No media selected'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Hide the progress snackbar
      scaffoldMessenger.hideCurrentSnackBar();
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Some files failed to save or delete'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _pickVideo(BuildContext context) async {
    // Get provider reference before closing dialog
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Navigator.pop(context);

    try {
      await mediaProvider.addVideoFromGallery(folderId, context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Video secured and hidden from gallery'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to add video'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _takePhoto(BuildContext context) async {
    // Get provider reference before closing dialog
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Navigator.pop(context);

    try {
      await mediaProvider.takePhoto(folderId, context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Photo captured and secured'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to take photo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
