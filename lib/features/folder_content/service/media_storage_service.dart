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
  static const platform = MethodChannel('com.example.locker/media_scanner');

  // Save media file to secure storage
  Future<MediaItem> saveMediaFile(
    File originalFile,
    String folderId,
    MediaType type,
    String originalName,
  ) async {
    try {
      debugPrint('📂 Starting to save media file: $originalName');
      
      // Get application documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String secureDirPath = '${appDir.path}/secure_media/$folderId';
      final Directory secureDir = Directory(secureDirPath);

      if (!await secureDir.exists()) {
        await secureDir.create(recursive: true);
        debugPrint('✅ Created secure directory: $secureDirPath');
      }

      // Generate unique filename
      final String fileExtension = originalName.split('.').last;
      final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      final String newFileName = '$uniqueId.$fileExtension';
      final String newFilePath = '$secureDirPath/$newFileName';

      // Copy file to secure location
      await originalFile.copy(newFilePath);
      debugPrint('✅ Copied file to secure location: $newFilePath');

      // Delete original file from gallery to hide it
      final bool deleted = await _deleteOriginalFileFromGallery(originalFile);
      if (deleted) {
        debugPrint('✅ Successfully deleted original file from gallery');
      } else {
        debugPrint('⚠️ Could not delete original file, but it may be a cache file');
      }

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

      debugPrint('✅ Media file saved successfully: ${mediaItem.name}');
      return mediaItem;
    } catch (e) {
      debugPrint('❌ Error saving media file: $e');
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
        debugPrint('✅ Created .nomedia file in: $directoryPath');
      }
    } catch (e) {
      debugPrint('Error creating .nomedia file: $e');
    }
  }

  // Delete original file from gallery - IMPORTANT NOTES:
  // 
  // ⚠️ ANDROID SCOPED STORAGE LIMITATION:
  // On Android 10+ (API 29+), image_picker returns CACHED COPIES of files, not originals.
  // This means:
  // 1. When user picks from gallery → Android creates a temp copy in cache
  // 2. We can delete this cache copy ✅
  // 3. BUT the original file REMAINS in the gallery ❌
  // 
  // WHY: Android's Scoped Storage security model prevents direct file access
  // 
  // SOLUTIONS (for future implementation):
  // 1. Use file_picker with proper permissions (complex)
  // 2. Ask user to manually delete from gallery
  // 3. Clearly communicate that files are "secured/copied" not "moved"
  // 
  // CURRENT BEHAVIOR:
  // - Deletes cache files ✅
  // - Creates secure copy in app ✅
  // - Hides app folder from gallery (.nomedia) ✅
  // - Original gallery files remain (by Android design) ℹ️
  //
  Future<bool> _deleteOriginalFileFromGallery(File originalFile) async {
    try {
      final String filePath = originalFile.path;
      debugPrint('🗑️ Attempting to delete: $filePath');
      
      // Check if this is a cached file (from image_picker) or an actual gallery file
      if (filePath.contains('/cache/') || 
          filePath.contains('image_picker') || 
          filePath.contains('scaled_')) {
        // This is a temporary cache file, just delete it
        if (await originalFile.exists()) {
          await originalFile.delete();
          debugPrint('✅ Deleted cache file: $filePath');
        }
        return true;
      }

      // For actual gallery files on Android
      if (Platform.isAndroid) {
        // Request necessary permissions
        bool permissionGranted = await _requestStoragePermissions();
        
        if (!permissionGranted) {
          debugPrint('⚠️ Storage permission not granted');
          // Still try to delete the file even without permission
        }

        // Use native method to delete from gallery
        try {
          final bool nativeDeleteSuccess = await platform.invokeMethod(
            'deleteFromGallery',
            {'path': filePath},
          );
          
          if (nativeDeleteSuccess) {
            debugPrint('✅ Successfully deleted from gallery via native code');
            return true;
          }
        } catch (e) {
          debugPrint('⚠️ Native delete failed: $e');
        }

        // Fallback: Try direct file deletion
        if (await originalFile.exists()) {
          try {
            await originalFile.delete();
            debugPrint('✅ Deleted file directly: $filePath');
            
            // Trigger media scan to update gallery
            await _refreshMediaGallery(filePath);
            return true;
          } catch (e) {
            debugPrint('⚠️ Could not delete file: $e');
          }
        }
      } else if (Platform.isIOS) {
        // iOS handles this differently - files picked from gallery are copies
        if (await originalFile.exists()) {
          await originalFile.delete();
          debugPrint('✅ Deleted iOS temp file: $filePath');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error in _deleteOriginalFileFromGallery: $e');
      return false;
    }
  }

  // Request storage permissions
  Future<bool> _requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+)
        if (await Permission.photos.isGranted || 
            await Permission.videos.isGranted) {
          return true;
        }
        
        // Request media permissions
        Map<Permission, PermissionStatus> statuses = await [
          Permission.photos,
          Permission.videos,
        ].request();
        
        bool allGranted = statuses.values.every((status) => status.isGranted);
        
        if (!allGranted) {
          // Try MANAGE_EXTERNAL_STORAGE for Android 11+
          var manageStatus = await Permission.manageExternalStorage.status;
          if (!manageStatus.isGranted) {
            manageStatus = await Permission.manageExternalStorage.request();
          }
          return manageStatus.isGranted;
        }
        
        return allGranted;
      }
      return true; // iOS doesn't need explicit permission for this
    } catch (e) {
      debugPrint('⚠️ Error requesting permissions: $e');
      return false;
    }
  }

  // Refresh media gallery to remove deleted files from system index
  Future<void> _refreshMediaGallery(String filePath) async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('scanFile', {'path': filePath});
        debugPrint('📱 Media gallery refreshed for: $filePath');
      }
    } catch (e) {
      debugPrint('⚠️ Could not refresh media gallery: $e');
    }
  }

  // Delete media file by URI (for file_picker approach)
  Future<bool> deleteMediaByUri(String uri) async {
    try {
      if (Platform.isAndroid) {
        debugPrint('🗑️ Deleting media by URI: $uri');
        final bool success = await platform.invokeMethod(
          'deleteMediaByUri',
          {'uri': uri},
        );
        if (success) {
          debugPrint('✅ Successfully deleted from gallery via URI');
        } else {
          debugPrint('⚠️ Failed to delete via URI');
        }
        return success;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting media by URI: $e');
      return false;
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

      // Request permissions
      await _requestStoragePermissions();

      // Use platform-specific restoration
      if (Platform.isAndroid) {
        // Copy to DCIM/Restored directory
        final Directory dcimDir = Directory('/storage/emulated/0/DCIM/Restored');
        if (!await dcimDir.exists()) {
          await dcimDir.create(recursive: true);
        }

        final String targetPath = '${dcimDir.path}/${mediaItem.name}';
        await sourceFile.copy(targetPath);

        // Trigger media scan
        await platform.invokeMethod('scanFile', {'path': targetPath});
        
        debugPrint('✅ Restored to Android gallery: ${mediaItem.name}');
        return true;
      } else if (Platform.isIOS) {
        // For iOS, we would need to use Photos framework
        // This is a simplified version
        debugPrint('⚠️ iOS restoration needs Photos framework implementation');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error restoring media to gallery: $e');
      return false;
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
