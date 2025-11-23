# Security Feature Documentation

## Overview
The app now includes a comprehensive PIN-based security system that protects access to your private media vault.

## Features

### 1. PIN Setup (First Time)
- When users launch the app for the first time, they are prompted to set up a 4-6 digit PIN
- PIN is securely hashed using SHA-256 encryption before storage
- Confirmation required to prevent typos
- Visual feedback with show/hide toggle for PIN entry

### 2. PIN Login (Subsequent Access)
- Users must enter their PIN to access the app
- Failed attempt tracking with visual feedback
- Auto-focus on PIN input for better UX
- Lock icon indicates secure access

### 3. App Locking
- Users can lock the app anytime using the lock button in the home screen
- Forces re-authentication with PIN
- Protects privacy when device is shared

### 4. Media Gallery Hiding
- All photos and videos added to the app are automatically hidden from the device gallery
- Uses `.nomedia` files in secure storage directories
- Media is stored in app-specific directories that are not indexed by system media scanners
- Complete privacy from other apps and gallery viewers

### 5. Restore Functionality
- Users can restore media back to the device gallery
- Single item restore or batch restore options
- Select all functionality for bulk operations
- Restored media appears in `/DCIM/Restored` folder

### 6. Delete Functionality
- Permanently delete media from the app
- Single or batch delete with selection mode
- Confirmation dialogs prevent accidental deletion
- Thumbnails are also deleted automatically

## Architecture

### Security Module Structure
```
lib/features/security/
├── models/
│   └── security_settings.dart      # Data model for security settings
├── services/
│   └── security_service.dart       # Core security operations (hashing, storage)
├── provider/
│   └── security_provider.dart      # State management for authentication
└── presentation/
    ├── splash_screen.dart          # Initial routing logic
    ├── pin_setup_screen.dart       # First-time PIN creation
    └── pin_login_screen.dart       # PIN authentication
```

### Key Components

#### SecurityService
- **PIN Hashing**: Uses SHA-256 to securely hash PINs
- **Persistent Storage**: Uses SharedPreferences for encrypted PIN storage
- **Verification**: Compares hashed PINs for authentication
- **Change PIN**: Allows users to update their PIN

#### SecurityProvider
- Manages authentication state across the app
- Integrates with Provider pattern for reactive UI updates
- Handles PIN setup, verification, and logout
- Tracks authentication status

#### Splash Screen
- Determines app flow based on security status:
  - No PIN set → PIN Setup Screen
  - PIN set but not authenticated → PIN Login Screen
  - Authenticated → Home Screen

## Usage

### For Users

1. **First Launch**
   - Set up a 4-6 digit PIN
   - Confirm the PIN
   - Access the home screen

2. **Daily Use**
   - Enter PIN to unlock the app
   - Add photos/videos (automatically hidden from gallery)
   - Lock app when done using the lock button

3. **Managing Media**
   - **Hide**: Media is automatically hidden when added
   - **Restore**: Use selection mode → select items → tap green restore button
   - **Delete**: Use selection mode → select items → tap red delete button

4. **Selection Mode**
   - Tap checklist icon to enter selection mode
   - Tap items to select/deselect
   - Use "Select All" or "Deselect All" buttons
   - Perform batch operations

### For Developers

#### Adding Security to New Screens
```dart
// Check authentication before accessing sensitive screens
final securityProvider = Provider.of<SecurityProvider>(context, listen: false);
if (!securityProvider.isAuthenticated) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => PinLoginScreen()),
  );
}
```

#### Implementing Logout
```dart
final securityProvider = Provider.of<SecurityProvider>(context, listen: false);
securityProvider.logout();
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => PinLoginScreen()),
  (route) => false,
);
```

## Security Considerations

### Implemented
✅ PIN is hashed using SHA-256 before storage  
✅ No plain-text PIN storage  
✅ Media hidden from gallery using `.nomedia` files  
✅ Secure app-specific storage directories  
✅ Authentication state management  
✅ Failed attempt tracking  

### Recommended Enhancements
- Biometric authentication (fingerprint/face ID)
- PIN complexity requirements
- Account lockout after multiple failed attempts
- Encrypted file storage
- Two-factor authentication
- PIN recovery mechanism
- Auto-lock after inactivity

## Dependencies

```yaml
dependencies:
  crypto: ^3.0.3                 # For SHA-256 hashing
  shared_preferences: ^2.2.2     # For persistent storage
  provider: ^6.1.5+1             # State management
  path_provider: ^2.1.5          # Secure file paths
```

## File Structure

### Media Storage
- **Secure Storage**: `/app_directory/secure_media/{folderId}/`
  - Contains media files
  - Includes `.nomedia` file to hide from gallery
  
- **Restored Media**: `/DCIM/Restored/`
  - Public directory for restored media
  - Visible in device gallery

### PIN Storage
- **Location**: SharedPreferences
- **Key**: `security_settings`
- **Format**: JSON with hashed PIN and metadata

## Testing

### Test Cases

1. **PIN Setup**
   - Test minimum length (4 digits)
   - Test mismatch between PIN and confirmation
   - Test successful setup

2. **PIN Login**
   - Test correct PIN
   - Test incorrect PIN
   - Test failed attempt tracking

3. **Media Hiding**
   - Add photo → verify not in gallery
   - Add video → verify not in gallery
   - Check `.nomedia` file exists

4. **Restore Function**
   - Restore single item → verify in gallery
   - Restore multiple items → verify all in gallery
   - Check restored location

5. **Delete Function**
   - Delete single item → verify removed
   - Delete multiple items → verify all removed
   - Check thumbnails deleted

## Troubleshooting

### PIN Not Working
- Check SharedPreferences initialization
- Verify crypto package is installed
- Check for proper hashing implementation

### Media Still Visible in Gallery
- Verify `.nomedia` file exists in secure directory
- Check file permissions
- Force gallery refresh (restart device)

### Authentication State Issues
- Check Provider initialization in main.dart
- Verify SecurityProvider is accessible in widget tree
- Check async initialization completion

## Future Improvements

1. **Enhanced Security**
   - Add biometric authentication
   - Implement encrypted file storage
   - Add secure backup/restore

2. **User Experience**
   - PIN recovery options
   - Multiple PIN profiles
   - Quick unlock shortcuts

3. **Advanced Features**
   - Auto-lock timer
   - Intruder selfie on failed attempts
   - Fake PIN for decoy vault

## Support

For issues or questions, refer to the main README.md or raise an issue in the repository.
