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
    Navigator.pop(context);
    try {
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      await mediaProvider.addImageFromGallery(folderId, context);
      _showSuccessSnackbar(context, 'Image added successfully');
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to add image');
    }
  }

  void _pickVideo(BuildContext context) async {
    Navigator.pop(context);
    try {
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      await mediaProvider.addVideoFromGallery(folderId, context);
      _showSuccessSnackbar(context, 'Video added successfully');
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to add video');
    }
  }

  void _takePhoto(BuildContext context) async {
    Navigator.pop(context);
    try {
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      await mediaProvider.takePhoto(folderId, context);
      _showSuccessSnackbar(context, 'Photo taken successfully');
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to take photo');
    }
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}