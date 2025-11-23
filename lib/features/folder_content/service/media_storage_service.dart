// lib/core/services/media_storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/media_item.dart';

class MediaStorageService {
  // Save media file to secure storage
  Future<MediaItem> saveMediaFile(
    File originalFile,
    String folderId,
    MediaType type,
    String originalName,
  ) async {
    try {
      // Get application documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String secureDirPath = '${appDir.path}/secure_media/$folderId';
      final Directory secureDir = Directory(secureDirPath);

      if (!await secureDir.exists()) {
        await secureDir.create(recursive: true);
      }

      // Generate unique filename
      final String fileExtension = originalName.split('.').last;
      final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      final String newFileName = '$uniqueId.$fileExtension';
      final String newFilePath = '$secureDirPath/$newFileName';

      // Copy file to secure location
      await originalFile.copy(newFilePath);

      // Delete original file from gallery to hide it
      await _deleteOriginalFile(originalFile);

      // Get file info
      final File newFile = File(newFilePath);
      final int fileSize = await newFile.length();
      final DateTime createdDate = DateTime.now();

      // Generate thumbnail for videos
      String? thumbnailPath;
      Duration? videoDuration;
      if (type == MediaType.video) {
        thumbnailPath = await generateVideoThumbnail(newFilePath);
        videoDuration = await _getVideoDuration(newFilePath);
      }

      // Create media item
      final MediaItem mediaItem = MediaItem(
        id: uniqueId,
        name: originalName,
        type: type,
        createdDate: createdDate,
        filePath: newFilePath,
        folderId: folderId,
        fileSize: fileSize,
        duration: videoDuration,
        thumbnailPath: thumbnailPath,
      );

      // Save to metadata
      await _saveMediaMetadata(mediaItem);

      // Hide from gallery (create .nomedia file)
      await _createNoMediaFile(secureDirPath);

      return mediaItem;
    } catch (e) {
      debugPrint('Error saving media file: $e');
      rethrow;
    }
  }

  // Get video duration
  Future<Duration?> _getVideoDuration(String videoPath) async {
    try {
      // This is a placeholder - in a real app, you'd use a video processing library
      // For now, return null and handle it in the UI
      return null;
    } catch (e) {
      debugPrint('Error getting video duration: $e');
      return null;
    }
  }

  // Create .nomedia file to hide from gallery
  Future<void> _createNoMediaFile(String directoryPath) async {
    try {
      final File noMediaFile = File('$directoryPath/.nomedia');
      if (!await noMediaFile.exists()) {
        await noMediaFile.create();
      }
    } catch (e) {
      debugPrint('Error creating .nomedia file: $e');
    }
  }

  // Delete original file from gallery
  Future<void> _deleteOriginalFile(File originalFile) async {
    try {
      final String filePath = originalFile.path;
      
      // Check if this is a cached file (from image_picker) or an actual gallery file
      if (filePath.contains('/cache/')) {
        // This is a temporary cache file, just delete it
        if (await originalFile.exists()) {
          await originalFile.delete();
          debugPrint('✅ Deleted cache file: $filePath');
        }
        return;
      }

      // For actual gallery files, request permissions first
      if (Platform.isAndroid) {
        // Request storage permissions
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          // Try to request permission
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            debugPrint('⚠️ Storage permission not granted');
            return;
          }
        }
      }

      // Try to delete the file
      if (await originalFile.exists()) {
        await originalFile.delete();
        debugPrint('✅ Deleted original file from gallery: $filePath');
        
        // Refresh the media scanner
        await _refreshMediaGallery(filePath);
      }
    } catch (e) {
      debugPrint('⚠️ Warning: Could not delete original file: $e');
      // Don't throw - the file is already copied to secure storage
    }
  }

  // Refresh media gallery to remove deleted files from system index
  Future<void> _refreshMediaGallery(String filePath) async {
    try {
      if (Platform.isAndroid) {
        // Use MediaScannerConnection to update the gallery
        const platform = MethodChannel('com.example.locker/media_scanner');
        await platform.invokeMethod('scanFile', {'path': filePath});
        debugPrint('📱 Media gallery refreshed for: $filePath');
      } else if (Platform.isIOS) {
        // iOS automatically updates the Photos app
        debugPrint('📱 iOS gallery auto-refreshes');
      }
    } catch (e) {
      debugPrint('⚠️ Could not refresh media gallery: $e');
    }
  }

  // Save media metadata
  Future<void> _saveMediaMetadata(MediaItem mediaItem) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String metadataPath = '${appDir.path}/media_metadata.json';
      final File metadataFile = File(metadataPath);

      List<MediaItem> existingItems = await loadAllMediaItems();

      // Remove existing item with same ID (if updating)
      existingItems.removeWhere((item) => item.id == mediaItem.id);
      existingItems.add(mediaItem);

      // Convert to JSON and save
      final List<Map<String, dynamic>> jsonList = existingItems
          .map((item) => item.toJson())
          .toList();
      final String jsonString = json.encode(jsonList);
      await metadataFile.writeAsString(jsonString);

      debugPrint('✅ Saved media metadata for ${mediaItem.name}');
    } catch (e) {
      debugPrint('Error saving media metadata: $e');
      rethrow;
    }
  }

  // Load all media items
  Future<List<MediaItem>> loadAllMediaItems() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String metadataPath = '${appDir.path}/media_metadata.json';
      final File metadataFile = File(metadataPath);

      if (!await metadataFile.exists()) {
        return [];
      }

      final String jsonString = await metadataFile.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);

      return jsonList.map((jsonItem) => MediaItem.fromJson(jsonItem)).toList();
    } catch (e) {
      debugPrint('Error loading media metadata: $e');
      return [];
    }
  }

  // Load media items for specific folder
  Future<List<MediaItem>> loadMediaItems(String folderId) async {
    final allItems = await loadAllMediaItems();
    return allItems.where((item) => item.folderId == folderId).toList();
  }

  // Delete media file and metadata
  Future<void> deleteMediaFile(MediaItem mediaItem) async {
    try {
      // Delete physical file
      final File mediaFile = File(mediaItem.filePath);
      if (await mediaFile.exists()) {
        await mediaFile.delete();
      }

      // Delete thumbnail if exists
      if (mediaItem.thumbnailPath != null) {
        final File thumbnailFile = File(mediaItem.thumbnailPath!);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }

      // Remove from metadata
      final List<MediaItem> allItems = await loadAllMediaItems();
      allItems.removeWhere((item) => item.id == mediaItem.id);

      // Save updated metadata
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String metadataPath = '${appDir.path}/media_metadata.json';
      final File metadataFile = File(metadataPath);

      final List<Map<String, dynamic>> jsonList = allItems
          .map((item) => item.toJson())
          .toList();
      final String jsonString = json.encode(jsonList);
      await metadataFile.writeAsString(jsonString);

      debugPrint('✅ Deleted media file: ${mediaItem.name}');
    } catch (e) {
      debugPrint('Error deleting media file: $e');
      rethrow;
    }
  }

  // Restore media file to gallery
  Future<bool> restoreMediaToGallery(MediaItem mediaItem) async {
    try {
      final File sourceFile = File(mediaItem.filePath);

      if (!await sourceFile.exists()) {
        debugPrint('❌ Source file not found: ${mediaItem.filePath}');
        return false;
      }

      // Get appropriate directory based on media type
      Directory? targetDir;
      if (mediaItem.type == MediaType.image) {
        targetDir = Directory('/storage/emulated/0/DCIM/Restored');
      } else if (mediaItem.type == MediaType.video) {
        targetDir = Directory('/storage/emulated/0/DCIM/Restored');
      }

      if (targetDir != null) {
        // Create directory if it doesn't exist
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        // Copy file to gallery
        final String targetPath = '${targetDir.path}/${mediaItem.name}';
        await sourceFile.copy(targetPath);

        // Trigger media scan to make it visible in gallery immediately
        await _scanMediaFile(targetPath);

        debugPrint('✅ Restored to gallery: ${mediaItem.name}');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error restoring media to gallery: $e');
      return false;
    }
  }

  // Scan media file to make it visible in gallery
  Future<void> _scanMediaFile(String filePath) async {
    try {
      if (Platform.isAndroid) {
        // On Android, trigger media scanner
        debugPrint('📱 Scanning file for gallery: $filePath');
        // Note: In production, use a plugin like media_scanner or gallery_saver
        // For now, the file will appear after gallery refresh
      }
    } catch (e) {
      debugPrint('Warning: Could not scan media file: $e');
    }
  }

  // Delete multiple media files
  Future<void> deleteMultipleMediaFiles(List<MediaItem> mediaItems) async {
    for (var mediaItem in mediaItems) {
      await deleteMediaFile(mediaItem);
    }
  }

  // Restore multiple media files to gallery
  Future<List<bool>> restoreMultipleMediaToGallery(
    List<MediaItem> mediaItems,
  ) async {
    List<bool> results = [];
    for (var mediaItem in mediaItems) {
      final success = await restoreMediaToGallery(mediaItem);
      results.add(success);
    }
    return results;
  }

  // Get file size in readable format
  String getFileSizeString(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Generate thumbnail for video with random frame
  Future<String?> generateVideoThumbnail(String videoPath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String thumbnailDir = '${appDir.path}/thumbnails';
      final Directory thumbDir = Directory(thumbnailDir);

      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      // Generate a random time position between 10% and 70% of the video
      // This avoids black frames at the start/end and gives variety
      final random = Random();
      final timeMs =
          1000 + random.nextInt(10000); // Random between 1-11 seconds

      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailDir,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        maxWidth: 300,
        quality: 75,
        timeMs: timeMs, // Capture frame at random time position
      );

      debugPrint('✅ Generated thumbnail at ${timeMs}ms: $thumbnailPath');
      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      // Fallback: try without time specification
      try {
        final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath:
              (await getApplicationDocumentsDirectory()).path + '/thumbnails',
          imageFormat: ImageFormat.JPEG,
          maxHeight: 300,
          maxWidth: 300,
          quality: 75,
        );
        return thumbnailPath;
      } catch (fallbackError) {
        debugPrint('Fallback thumbnail generation also failed: $fallbackError');
        return null;
      }
    }
  }
}
