// lib/features/home/provider/home_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/home_category.dart';
import '../services/local_storage_service.dart';

class HomeProvider with ChangeNotifier {
  List<HomeCategory> _categories = [];
  List<HomeCategory> _customFolders = [];

  List<HomeCategory> get categories => _categories;
  List<HomeCategory> get customFolders => _customFolders;
  List<HomeCategory> get allFolders => [..._categories, ..._customFolders];

  // Available color options for folders
  final List<ColorOption> colorOptions = [
    ColorOption(
      name: 'Blue',
      color: Colors.blue,
      gradient: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
    ),
    ColorOption(
      name: 'Red',
      color: Colors.red,
      gradient: [Color(0xFFF72585), Color(0xFFB5179E)],
    ),
    ColorOption(
      name: 'Green',
      color: Colors.green,
      gradient: [Color(0xFF4CC9F0), Color(0xFF4895EF)],
    ),
    ColorOption(
      name: 'Orange',
      color: Colors.orange,
      gradient: [Color(0xFFFF9E00), Color(0xFFFF7B00)],
    ),
    ColorOption(
      name: 'Purple',
      color: Colors.purple,
      gradient: [Color(0xFF7209B7), Color(0xFF560BAD)],
    ),
    ColorOption(
      name: 'Teal',
      color: Colors.teal,
      gradient: [Color(0xFF4DB6AC), Color(0xFF00796B)],
    ),
    ColorOption(
      name: 'Pink',
      color: Colors.pink,
      gradient: [Color(0xFFEC407A), Color(0xFFAD1457)],
    ),
    ColorOption(
      name: 'Indigo',
      color: Colors.indigo,
      gradient: [Color(0xFF5C6BC0), Color(0xFF283593)],
    ),
  ];

  HomeProvider() {
    _initializeDefaultCategories();
    _loadCustomFolders();
  }

  void _initializeDefaultCategories() {
    _categories = [
      HomeCategory(
        id: '1',
        title: 'Images',
        icon: Icons.photo_library_rounded,
        color: colorOptions[0].color,
        gradient: colorOptions[0].gradient,
        count: 0,
        type: 'images',
        createdAt: DateTime.now(),
        isCustom: false,
      ),
      HomeCategory(
        id: '2',
        title: 'Videos',
        icon: Icons.video_library_rounded,
        color: colorOptions[1].color,
        gradient: colorOptions[1].gradient,
        count: 0,
        type: 'videos',
        createdAt: DateTime.now(),
        isCustom: false,
      ),
      HomeCategory(
        id: '3',
        title: 'Documents',
        icon: Icons.description_rounded,
        color: colorOptions[2].color,
        gradient: colorOptions[2].gradient,
        count: 0,
        type: 'documents',
        createdAt: DateTime.now(),
        isCustom: false,
      ),
      HomeCategory(
        id: '4',
        title: 'Private',
        icon: Icons.lock_rounded,
        color: colorOptions[3].color,
        gradient: colorOptions[3].gradient,
        count: 0,
        type: 'private',
        createdAt: DateTime.now(),
        isCustom: false,
      ),
    ];
  }

  // Load custom folders from local storage
  Future<void> _loadCustomFolders() async {
    try {
      final foldersData = await LocalStorageService.loadCustomFolders();
      _customFolders = foldersData.map((folderData) {
        return HomeCategory.fromJson(folderData);
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading custom folders: $e');
      _customFolders = [];
    }
  }

  // Create new folder with color selection
  Future<void> createNewFolder(String folderName, ColorOption colorOption) async {
    final newFolder = HomeCategory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: folderName,
      icon: Icons.folder_rounded,
      color: colorOption.color,
      gradient: colorOption.gradient,
      count: 0,
      type: 'custom',
      createdAt: DateTime.now(),
      isCustom: true,
    );

    _customFolders.add(newFolder);
    await _saveCustomFolders();
    notifyListeners();
  }

  // Update folder
  Future<void> updateFolder(String folderId, String newName, ColorOption colorOption) async {
    final index = _customFolders.indexWhere((folder) => folder.id == folderId);
    if (index != -1) {
      _customFolders[index] = _customFolders[index].copyWith(
        title: newName,
        color: colorOption.color,
        gradient: colorOption.gradient,
      );
      await _saveCustomFolders();
      notifyListeners();
    }
  }

  // Update folder count from media provider
  void updateFolderCount(String folderId, int newCount) {
    // Update custom folders
    final customFolderIndex = _customFolders.indexWhere((folder) => folder.id == folderId);
    if (customFolderIndex != -1) {
      _customFolders[customFolderIndex] = _customFolders[customFolderIndex].copyWith(count: newCount);
      _saveCustomFolders();
    }
    // Update default categories
    else {
      final categoryIndex = _categories.indexWhere((folder) => folder.id == folderId);
      if (categoryIndex != -1) {
        _categories[categoryIndex] = _categories[categoryIndex].copyWith(count: newCount);
      }
    }
    notifyListeners();
  }

  // Update all folder counts from media data
  Future<void> syncFolderCounts(Map<String, int> folderCounts) async {
    // Update custom folders
    for (var folder in _customFolders) {
      final count = folderCounts[folder.id] ?? 0;
      final index = _customFolders.indexWhere((f) => f.id == folder.id);
      if (index != -1) {
        _customFolders[index] = _customFolders[index].copyWith(count: count);
      }
    }

    // Update default categories
    for (var category in _categories) {
      final count = folderCounts[category.id] ?? 0;
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = _categories[index].copyWith(count: count);
      }
    }

    await _saveCustomFolders();
    notifyListeners();
  }

  // Delete folder
  Future<void> deleteFolder(String folderId) async {
    _customFolders.removeWhere((folder) => folder.id == folderId);
    await _saveCustomFolders();
    notifyListeners();
  }

  // Save to local storage
  Future<void> _saveCustomFolders() async {
    try {
      final foldersData = _customFolders.map((folder) => folder.toJson()).toList();
      await LocalStorageService.saveCustomFolders(foldersData);
      debugPrint('✅ Saved ${_customFolders.length} custom folders to local storage');
    } catch (e) {
      debugPrint('❌ Error saving custom folders: $e');
    }
  }

  // Get total items count
  int get totalItems {
    return allFolders.fold(0, (sum, folder) => sum + folder.count);
  }

  // Get folder by ID
  HomeCategory? getFolderById(String folderId) {
    try {
      return allFolders.firstWhere((folder) => folder.id == folderId);
    } catch (e) {
      return null;
    }
  }

  // Check if folder name already exists (excluding current folder)
  bool isFolderNameExists(String folderName, {String? excludeFolderId}) {
    return allFolders.any((folder) =>
    folder.title.toLowerCase() == folderName.toLowerCase() &&
        folder.id != excludeFolderId
    );
  }
}

// Color option model
class ColorOption {
  final String name;
  final Color color;
  final List<Color> gradient;

  ColorOption({
    required this.name,
    required this.color,
    required this.gradient,
  });
}