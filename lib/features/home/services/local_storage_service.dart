// lib/core/services/local_storage_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _customFoldersKey = 'custom_folders';

  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // Save custom folders
  static Future<bool> saveCustomFolders(
    List<Map<String, dynamic>> folders,
  ) async {
    try {
      final prefs = await _prefs;
      final String encodedData = json.encode(folders);
      return await prefs.setString(_customFoldersKey, encodedData);
    } catch (e) {
      debugPrint('Error saving custom folders: $e');
      return false;
    }
  }

  // Load custom folders
  static Future<List<Map<String, dynamic>>> loadCustomFolders() async {
    try {
      final prefs = await _prefs;
      final String? foldersString = prefs.getString(_customFoldersKey);

      if (foldersString != null) {
        final List<dynamic> foldersList = json.decode(foldersString);
        return foldersList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading custom folders: $e');
      return [];
    }
  }

  // Clear all data (for testing)
  static Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
