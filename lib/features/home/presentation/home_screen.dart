// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:locker/features/home/presentation/widgets/catagory_card.dart';
import 'package:locker/features/home/presentation/widgets/create_folder_dialog.dart';
import 'package:locker/features/home/presentation/widgets/security_status_card.dart';
import 'package:provider/provider.dart';
import '../../folder_content/presentation/folder_content_screen.dart';
import '../../folder_content/provider/media_provider.dart';
import '../../security/provider/security_provider.dart';
import '../../security/presentation/pin_login_screen.dart';
import '../models/home_category.dart';
import '../provider/home_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SecurityProvider _securityProvider;

  @override
  void initState() {
    super.initState();
    _securityProvider = Provider.of<SecurityProvider>(context, listen: false);
    // Trigger media loading to sync counts on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      mediaProvider.loadMediaForFolder(''); // Load all media to sync counts

      // Initialize auto-lock feature
      final securityProvider = Provider.of<SecurityProvider>(
        context,
        listen: false,
      );
      securityProvider.initializeAutoLock();
    });
  }

  @override
  void dispose() {
    // Clean up auto-lock when leaving home screen
    _securityProvider.disposeAutoLock();
    super.dispose();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E2E),
        title: Text('Lock App', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to lock the app?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              _securityProvider.logout();

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => PinLoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Color(0xFF4361EE)),
            child: Text('Lock', style: TextStyle(color: Color(0xFF4361EE))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Secure Vault',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.lock_outline_rounded, color: Colors.white70),
            onPressed: _logout,
            tooltip: 'Lock App',
          ),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          final folders = homeProvider.allFolders;
          final totalItems = homeProvider.totalItems;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),

              // Security Status Card
              SecurityStatusCard(totalItems: totalItems),

              SizedBox(height: 30),

              // Categories Grid Title
              _buildFoldersTitle(folders),

              SizedBox(height: 16),

              // Categories Grid
              _buildFoldersGrid(homeProvider, folders),
            ],
          );
        },
      ),

      // Floating Action Button for New Folder
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateFolderDialog(context),
        backgroundColor: Color(0xFF4361EE),
        child: Icon(
          Icons.create_new_folder_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your digital safe is secured',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersTitle(List<HomeCategory> folders) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Your Folders',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${folders.length}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersGrid(
    HomeProvider homeProvider,
    List<HomeCategory> folders,
  ) {
    return Expanded(
      child: folders.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: EdgeInsets.all(20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final category = folders[index];
                final isCustomFolder = category.isCustom;

                return CategoryCard(
                  category: category,
                  showMenu: isCustomFolder,
                  onTap: () => _navigateToFolderScreen(context, category),
                  onEdit: isCustomFolder
                      ? () => _showEditFolderDialog(context, category)
                      : null,
                  onDelete: isCustomFolder
                      ? () => _showDeleteDialog(context, category, homeProvider)
                      : null,
                );
              },
            ),
    );
  }

  void _showEditFolderDialog(BuildContext context, HomeCategory folder) {
    showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(
        editFolder: folder,
        onCreateFolder: (folderName, colorOption) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          homeProvider.updateFolder(folder.id, folderName, colorOption);
        },
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    HomeCategory folder,
    HomeProvider homeProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E2E),
        title: Text('Delete Folder', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${folder.title}"? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              await homeProvider.deleteFolder(folder.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Folder "${folder.title}" deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: Colors.white38),
          SizedBox(height: 20),
          Text(
            'No folders yet',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          SizedBox(height: 10),
          Text(
            'Tap + to create your first folder',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(
        onCreateFolder: (folderName, colorOption) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          homeProvider.createNewFolder(folderName, colorOption);
        },
      ),
    );
  }

  void _navigateToFolderScreen(BuildContext context, HomeCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderContentScreen(category: category),
      ),
    );
  }
}
