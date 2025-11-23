// lib/core/services/media_storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/media_item.dart';

class MediaStorageService {
  static const String _mediaDataKey = 'media_items';

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

      // Get file info
      final File newFile = File(newFilePath);
      final int fileSize = await newFile.length();
      final DateTime createdDate = DateTime.now();

      // Create media item
      final MediaItem mediaItem = MediaItem(
        id: uniqueId,
        name: originalName,
        type: type,
        createdDate: createdDate,
        filePath: newFilePath,
        folderId: folderId,
        fileSize: fileSize,
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
      final List<Map<String, dynamic>> jsonList =
      existingItems.map((item) => item.toJson()).toList();
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

      // Remove from metadata
      final List<MediaItem> allItems = await loadAllMediaItems();
      allItems.removeWhere((item) => item.id == mediaItem.id);

      // Save updated metadata
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String metadataPath = '${appDir.path}/media_metadata.json';
      final File metadataFile = File(metadataPath);

      final List<Map<String, dynamic>> jsonList =
      allItems.map((item) => item.toJson()).toList();
      final String jsonString = json.encode(jsonList);
      await metadataFile.writeAsString(jsonString);

      debugPrint('✅ Deleted media file: ${mediaItem.name}');
    } catch (e) {
      debugPrint('Error deleting media file: $e');
      rethrow;
    }
  }

  // Get file size in readable format
  String getFileSizeString(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Generate thumbnail for video
  Future<String?> generateVideoThumbnail(String videoPath) async {
    try {
      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );
      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }
}