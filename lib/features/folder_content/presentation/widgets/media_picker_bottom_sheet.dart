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
              child: Text(
                'Add Media',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Divider(color: Colors.white24, height: 1),

            // Options
            _buildOptionTile(
              context,
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Select images from your gallery',
              onTap: () => _pickFromGallery(context),
            ),

            _buildOptionTile(
              context,
              icon: Icons.video_library_rounded,
              title: 'Choose Video',
              subtitle: 'Select videos from your gallery',
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
