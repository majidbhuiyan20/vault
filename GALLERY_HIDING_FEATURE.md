# Gallery Hiding Feature Documentation

## Overview
When users select photos or videos from the gallery to add to the app, the original files are automatically **deleted from the device gallery** and stored securely in the app. This ensures complete privacy and prevents the media from being visible in the system gallery or other apps.

## How It Works

### User Flow
1. **Select Media**: User taps "Choose from Gallery" or "Choose Video"
2. **Confirmation Dialog**: User sees a warning that the file will be hidden from gallery
3. **User Confirms**: Taps "Hide & Secure" button
4. **Processing**:
   - File is copied to secure app storage
   - Original file is deleted from device
   - `.nomedia` file is created to prevent indexing
   - Gallery is refreshed (system-dependent)
5. **Success**: Media is now only accessible in the app

### Confirmation Dialog
The dialog displays:
- ⚠️ **Warning**: Original file will be deleted from device
- ℹ️ **Information**:
  - File stored securely in app
  - Can restore to gallery anytime
  - Gallery updated automatically

## Technical Implementation

### Media Storage Service Updates

#### 1. Delete Original File
```dart
// After copying to secure storage, delete original
await _deleteOriginalFile(originalFile);
```

**Method**: `_deleteOriginalFile(File originalFile)`
- Checks if file exists
- Deletes the original file
- Handles permission errors gracefully
- Logs success/failure for debugging

#### 2. Refresh Gallery
```dart
// Notify system to update gallery index
await _refreshMediaGallery();
```

**Method**: `_refreshMediaGallery()`
- Platform-specific gallery refresh
- Android: Triggers media scanner
- iOS: Automatic (Photos app updates)
- Logs action for debugging

#### 3. Scan Restored Files
```dart
// When restoring, scan file to make visible in gallery
await _scanMediaFile(targetPath);
```

**Method**: `_scanMediaFile(String filePath)`
- Makes restored files immediately visible
- Triggers system media indexing
- Platform-specific implementation

### Media Picker Updates

#### Confirmation Dialog
New method: `_showHideConfirmationDialog()`

**Features**:
- Beautiful UI with warning icon
- Clear explanation of what will happen
- Orange accent for warning visibility
- List of key points (secure storage, restore option, auto-update)
- Cancel and Confirm buttons

**User Actions**:
- **Cancel**: Returns to app without adding media
- **Hide & Secure**: Proceeds with hiding the file

### Success Messages

Updated snackbar messages:
- Images: "Image secured and hidden from gallery"
- Videos: "Video secured and hidden from gallery"
- Camera: "Photo captured and secured"

## Security Features

### File Protection
✅ **Original Deleted**: Source file removed from device  
✅ **Secure Storage**: Stored in app-specific directory  
✅ **Hidden from Gallery**: `.nomedia` file prevents indexing  
✅ **Private Access**: Only accessible through app  
✅ **Restore Available**: Can be moved back to gallery anytime  

### Privacy Benefits
- Media not visible in system gallery
- Not accessible by other apps
- Not included in system media scans
- Protected by app PIN security
- Backed up separately from device photos

## User Experience

### Before Adding Media
1. User browses gallery in other apps
2. All photos/videos are visible
3. Media appears in gallery app

### After Adding to App
1. Selected media **disappears** from gallery
2. Only visible inside secure vault app
3. Other apps cannot access the media
4. Gallery app doesn't show it anymore

### Restoring Media
1. Open app and enter PIN
2. Navigate to folder with media
3. Enable selection mode
4. Select items to restore
5. Tap green restore button
6. Media appears back in gallery (in `/DCIM/Restored/`)

## Platform-Specific Behavior

### Android
- **Deletion**: Immediate
- **Gallery Update**: May require gallery app refresh
- **Restore Location**: `/storage/emulated/0/DCIM/Restored/`
- **Permissions**: WRITE_EXTERNAL_STORAGE required

### iOS
- **Deletion**: Immediate
- **Gallery Update**: Automatic (Photos app)
- **Restore Location**: Camera Roll / Photos Library
- **Permissions**: Photo Library access required

## Permissions

### Android Manifest
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

### iOS Info.plist
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Access photos to securely store them</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save photos back to your library</string>
```

## Error Handling

### Permission Denied
- **Issue**: App cannot delete original file
- **Behavior**: File copied to secure storage (still protected)
- **User Action**: Manually delete from gallery if desired
- **Logging**: Warning logged, no crash

### File Not Found
- **Issue**: Original file already deleted or moved
- **Behavior**: Continue with app storage
- **User Action**: None needed
- **Logging**: Info logged

### Gallery Refresh Failed
- **Issue**: System doesn't immediately update gallery
- **Behavior**: Gallery updates on next app launch/refresh
- **User Action**: Close and reopen gallery app
- **Logging**: Warning logged

## Testing

### Test Scenarios

#### 1. Basic Hide Test
```
1. Open gallery app, note photo count
2. Open secure vault app
3. Add photo from gallery with confirmation
4. Return to gallery app
5. ✓ Photo should be gone
6. ✓ Photo should appear in vault app
```

#### 2. Video Hide Test
```
1. Open gallery app, select a video
2. Note video location
3. Add video to vault app
4. Check original location
5. ✓ Video file should be deleted
6. ✓ Video should play in vault app
```

#### 3. Restore Test
```
1. Add photo to vault (it disappears from gallery)
2. Use restore function in vault
3. Check gallery app
4. ✓ Photo should appear in Restored folder
5. ✓ Original photo still in vault
```

#### 4. Multiple Files Test
```
1. Add 5 photos from gallery
2. Check gallery app
3. ✓ All 5 should be gone from gallery
4. ✓ All 5 should appear in vault
```

#### 5. Cancel Test
```
1. Tap "Choose from Gallery"
2. See confirmation dialog
3. Tap "Cancel"
4. ✓ No file should be added
5. ✓ Gallery should be unchanged
```

## Debug Logging

The feature includes comprehensive logging:

```
✅ Deleted original file from gallery: /path/to/file.jpg
⚠️ Warning: Could not delete original file: Permission denied
📱 Media gallery refresh triggered (Android)
📱 Scanning file for gallery: /DCIM/Restored/image.jpg
✅ Restored to gallery: photo_123.jpg
```

## Troubleshooting

### Files Not Disappearing from Gallery

**Causes**:
- Insufficient permissions
- Gallery app caching thumbnails
- Media scanner not triggered

**Solutions**:
1. Check app permissions in settings
2. Force close and reopen gallery app
3. Clear gallery app cache
4. Restart device (forces full media scan)

### Cannot Delete Original Files

**Causes**:
- Read-only storage
- Files on SD card (scoped storage)
- Android 11+ storage restrictions

**Solutions**:
1. Grant MANAGE_EXTERNAL_STORAGE permission
2. Move files from SD card to internal storage first
3. Check Android version compatibility

### Restored Files Not Appearing

**Causes**:
- Gallery not refreshed
- Wrong restore directory
- Media scanner not triggered

**Solutions**:
1. Close and reopen gallery app
2. Use "Scan Media" app or similar
3. Check `/DCIM/Restored/` folder manually
4. Restart device

## Important Notes

### Data Safety
⚠️ **Original files are permanently deleted**
- App maintains secure backup in app storage
- Files can be restored to gallery anytime
- Uninstalling app deletes secure storage
- **Recommend backing up important media before hiding**

### Storage Considerations
- Files stored in app-specific directory
- Takes up device storage space
- Counted as "App Data" in storage settings
- Cleared if app data is cleared

### Backup Implications
- Hidden files not included in device backup
- Not synced to Google Photos/iCloud automatically
- Need separate backup strategy for secured media
- Consider exporting important files regularly

## Future Enhancements

### Planned Features
1. **Cloud Sync**: Backup secured media to cloud
2. **Smart Scanning**: Auto-detect and suggest media scanner
3. **Batch Operations**: Hide multiple files at once
4. **Quick Hide**: Add from any app via share menu
5. **Export**: Bulk export to external storage

### Advanced Options
1. **Keep Original**: Option to copy instead of move
2. **Custom Locations**: Choose restore directory
3. **Auto-Hide**: Automatically hide new photos from camera
4. **Schedule Restore**: Temporary unhide with auto-hide

## Related Features

- [PIN Security](SECURITY_FEATURE.md)
- [Auto-Lock](AUTO_LOCK_FEATURE.md)
- [Restore Functionality](SECURITY_FEATURE.md#restore-functionality)
- [Delete Functionality](SECURITY_FEATURE.md#delete-functionality)

## Support

### Common Questions

**Q: Can I get files back if I uninstall the app?**
A: No. Always restore important files before uninstalling.

**Q: Why do some files still show in gallery?**
A: Gallery apps cache thumbnails. Force close and reopen the gallery app.

**Q: Can I choose to keep original?**
A: Currently no. This is planned for a future update.

**Q: Where are files stored?**
A: In app-specific storage: `/data/data/com.example.locker/files/secure_media/`

**Q: What happens to thumbnails?**
A: Thumbnails are also hidden and stored securely.

---

**Last Updated**: November 23, 2025  
**Feature Version**: 1.0  
**Status**: Production Ready
