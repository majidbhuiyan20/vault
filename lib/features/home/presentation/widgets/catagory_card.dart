// lib/features/home/presentation/widgets/category_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/home_provider.dart';
import '../../models/home_category.dart';

class CategoryCard extends StatelessWidget {
  final HomeCategory category;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showMenu;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.showMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        // Get the updated category with current count
        final updatedCategory =
            homeProvider.getFolderById(category.id) ?? category;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: updatedCategory.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: updatedCategory.gradient[0].withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background Pattern
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon and Menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Icon
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              updatedCategory.icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                          // Three-dot menu (only for custom folders)
                          if (showMenu && updatedCategory.isCustom)
                            _buildMenuButton(context),
                        ],
                      ),

                      Spacer(),

                      // Title and Count
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            updatedCategory.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${updatedCategory.count} items',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Lock badge for private category
                if (updatedCategory.title == 'Private')
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Colors.white70, size: 20),
      color: Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text('Edit Folder', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
