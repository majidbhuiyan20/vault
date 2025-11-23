// lib/features/home/presentation/widgets/create_folder_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/home_category.dart';
import '../../provider/home_provider.dart';

class CreateFolderDialog extends StatefulWidget {
  final Function(String, ColorOption) onCreateFolder;
  final HomeCategory? editFolder;

  const CreateFolderDialog({
    super.key,
    required this.onCreateFolder,
    this.editFolder,
  });

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final TextEditingController _folderNameController = TextEditingController();
  late ColorOption _selectedColor;

  @override
  void initState() {
    super.initState();
    if (widget.editFolder != null) {
      _folderNameController.text = widget.editFolder!.title;
      _selectedColor = _findMatchingColorOption(widget.editFolder!);
    } else {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      _selectedColor = homeProvider.colorOptions[4]; // Purple as default
    }
  }

  ColorOption _findMatchingColorOption(HomeCategory folder) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final matchingOption = homeProvider.colorOptions.firstWhere(
          (option) => option.color.value == folder.color.value,
      orElse: () => homeProvider.colorOptions[4], // Fallback to purple
    );
    return matchingOption;
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final isEdit = widget.editFolder != null;

    return Dialog(
      backgroundColor: Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              isEdit ? 'Edit Folder' : 'Create New Folder',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 20),

            // Folder Name Input
            TextField(
              controller: _folderNameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter folder name',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white38),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _selectedColor.color),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
              onSubmitted: (_) => _createOrUpdateFolder(homeProvider),
            ),

            SizedBox(height: 24),

            // Color Selection Title
            Text(
              'Choose Color',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 12),

            // Color Grid
            Container(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: homeProvider.colorOptions.map((colorOption) {
                  return _buildColorOption(colorOption);
                }).toList(),
              ),
            ),

            SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _createOrUpdateFolder(homeProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Update' : 'Create',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(ColorOption colorOption) {
    final isSelected = _selectedColor.color.value == colorOption.color.value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = colorOption;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colorOption.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: colorOption.color.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: isSelected
            ? Center(
          child: Icon(Icons.check_rounded, color: Colors.white, size: 20),
        )
            : SizedBox(),
      ),
    );
  }

  void _createOrUpdateFolder(HomeProvider homeProvider) {
    final folderName = _folderNameController.text.trim();

    if (folderName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a folder name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for duplicate folder names
    final isDuplicate = homeProvider.isFolderNameExists(
      folderName,
      excludeFolderId: widget.editFolder?.id,
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A folder with this name already exists'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    widget.onCreateFolder(folderName, _selectedColor);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }
}