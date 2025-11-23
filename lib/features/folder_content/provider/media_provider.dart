// lib/features/folder_content/provider/media_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import '../../home/provider/home_provider.dart';
import '../models/media_item.dart';
import '../service/media_storage_service.dart';

class MediaProvider with ChangeNotifier {
  final MediaStorageService _storageService;
  final List<MediaItem> _mediaItems = [];
  HomeProvider? _homeProvider;

  List<MediaItem> get mediaItems => List.unmodifiable(_mediaItems);
  bool get isEmpty => _mediaItems.isEmpty;

  MediaProvider(this._storageService) {
    _loadAllMedia();
  }

  void setHomeProvider(HomeProvider homeProvider) {
    _homeProvider = homeProvider;
    // Schedule sync after the current build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFolderCounts();
    });
  }

  // Load all media items on initialization
  Future<void> _loadAllMedia() async {
    try {
      final allItems = await _storageService.loadAllMediaItems();
      _mediaItems.clear();
      _mediaItems.addAll(allItems);
      _syncFolderCounts();
      notifyListeners();
      debugPrint('✅ Loaded ${_mediaItems.length} media items on startup');
    } catch (e) {
      debugPrint('Error loading all media: $e');
    }
  }

  Future<void> loadMediaForFolder(String folderId) async {
    try {
      // Reload all media items to ensure we have the latest data
      final allItems = await _storageService.loadAllMediaItems();
      _mediaItems.clear();
      _mediaItems.addAll(allItems);
      _syncFolderCounts();
      notifyListeners();
      debugPrint('✅ Reloaded ${_mediaItems.length} total media items');
    } catch (e) {
      debugPrint('Error loading media: $e');
    }
  }

  // Add image from gallery
  Future<void> addImageFromGallery(
    String folderId,
    BuildContext context,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        await _saveMediaFile(
          File(image.path),
          folderId,
          MediaType.image,
          image.name,
        );
        _syncFolderCounts();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  // Add video from gallery
  Future<void> addVideoFromGallery(
    String folderId,
    BuildContext context,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        await _saveMediaFile(
          File(video.path),
          folderId,
          MediaType.video,
          video.name,
        );
        _syncFolderCounts();
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      rethrow;
    }
  }

  // Take photo with camera
  Future<void> takePhoto(String folderId, BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (image != null) {
        await _saveMediaFile(
          File(image.path),
          folderId,
          MediaType.image,
          image.name,
        );
        _syncFolderCounts();
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      rethrow;
    }
  }

  // Save media file to secure storage
  Future<void> _saveMediaFile(
    File file,
    String folderId,
    MediaType type,
    String fileName,
  ) async {
    try {
      final mediaItem = await _storageService.saveMediaFile(
        file,
        folderId,
        type,
        fileName,
      );

      _mediaItems.add(mediaItem);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving media file: $e');
      rethrow;
    }
  }

  // Delete media item
  Future<void> deleteMediaItem(String mediaId, BuildContext context) async {
    try {
      final mediaItem = _mediaItems.firstWhere((item) => item.id == mediaId);
      await _storageService.deleteMediaFile(mediaItem);
      _mediaItems.removeWhere((item) => item.id == mediaId);
      _syncFolderCounts();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting media: $e');
      rethrow;
    }
  }

  // Delete multiple media items
  Future<void> deleteMultipleMediaItems(
    List<String> mediaIds,
    BuildContext context,
  ) async {
    try {
      final itemsToDelete = _mediaItems
          .where((item) => mediaIds.contains(item.id))
          .toList();

      await _storageService.deleteMultipleMediaFiles(itemsToDelete);
      _mediaItems.removeWhere((item) => mediaIds.contains(item.id));
      _syncFolderCounts();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting multiple media: $e');
      rethrow;
    }
  }

  // Restore media item to gallery
  Future<bool> restoreMediaItem(String mediaId, BuildContext context) async {
    try {
      final mediaItem = _mediaItems.firstWhere((item) => item.id == mediaId);
      final success = await _storageService.restoreMediaToGallery(mediaItem);

      if (success) {
        // Don't delete from app, just notify success
        debugPrint('✅ Media restored to gallery: ${mediaItem.name}');
      }

      return success;
    } catch (e) {
      debugPrint('Error restoring media: $e');
      return false;
    }
  }

  // Restore multiple media items to gallery
  Future<List<bool>> restoreMultipleMediaItems(
    List<String> mediaIds,
    BuildContext context,
  ) async {
    try {
      final itemsToRestore = _mediaItems
          .where((item) => mediaIds.contains(item.id))
          .toList();

      final results = await _storageService.restoreMultipleMediaToGallery(
        itemsToRestore,
      );

      return results;
    } catch (e) {
      debugPrint('Error restoring multiple media: $e');
      return [];
    }
  }

  // Sync folder counts with HomeProvider
  void _syncFolderCounts() {
    final homeProvider = _homeProvider;
    if (homeProvider == null) return;

    // Calculate counts for each folder
    final Map<String, int> folderCounts = {};
    for (var item in _mediaItems) {
      folderCounts.update(
        item.folderId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    // Update individual folder counts
    for (var folderId in folderCounts.keys) {
      homeProvider.updateFolderCount(folderId, folderCounts[folderId]!);
    }

    // Update folders with zero items
    final allFolderIds = homeProvider.allFolders.map((f) => f.id).toSet();
    for (var folderId in allFolderIds) {
      if (!folderCounts.containsKey(folderId)) {
        homeProvider.updateFolderCount(folderId, 0);
      }
    }
  }

  // Get media by ID
  MediaItem? getMediaById(String mediaId) {
    try {
      return _mediaItems.firstWhere((item) => item.id == mediaId);
    } catch (e) {
      return null;
    }
  }

  // Get media items for folder
  List<MediaItem> getMediaForFolder(String folderId) {
    return _mediaItems.where((item) => item.folderId == folderId).toList();
  }

  // Get count for specific folder
  int getFolderItemCount(String folderId) {
    return _mediaItems.where((item) => item.folderId == folderId).length;
  }

  // Clear all media (for testing)
  void clearMedia() {
    _mediaItems.clear();
    notifyListeners();
  }
}
