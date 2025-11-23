# Auto-Lock Feature Documentation

## Overview
The app now includes an automatic locking feature that secures the app when it goes to the background for 2 seconds or more.

## How It Works

### User Experience
1. User opens the app and enters PIN
2. User uses the app normally
3. User switches to another app or minimizes the app
4. After 2 seconds in the background, the app automatically locks
5. When user returns to the app, they must enter PIN again

### Technical Implementation

#### App Lifecycle Detection
The feature uses Flutter's `WidgetsBindingObserver` to monitor app lifecycle states:

```dart
AppLifecycleState.paused    // App goes to background
AppLifecycleState.inactive  // App is inactive (e.g., during phone call)
AppLifecycleState.hidden    // App is hidden
AppLifecycleState.resumed   // App returns to foreground
```

#### Time Tracking
- When app goes to background: Records timestamp
- When app returns: Calculates time difference
- If time >= 2 seconds: Triggers auto-lock

#### State Management
- Uses Provider pattern for reactive authentication state
- When auto-lock triggers, `SecurityProvider.logout()` is called
- The `AuthenticationWrapper` in main.dart automatically redirects to PIN login screen

## Architecture

### Components

#### 1. AppLifecycleManager
**Location**: `lib/features/security/services/app_lifecycle_manager.dart`

**Purpose**: Monitors app lifecycle and triggers auto-lock callback

**Key Features**:
- Implements `WidgetsBindingObserver`
- Tracks background time with millisecond precision
- Configurable lock duration
- Callback-based notification system

**Usage**:
```dart
final manager = AppLifecycleManager(
  lockDuration: Duration(seconds: 2),
  onShouldLock: () {
    // Lock the app
  },
);
manager.initialize(); // Start monitoring
manager.dispose();    // Stop monitoring
```

#### 2. SecurityProvider Updates
**Location**: `lib/features/security/provider/security_provider.dart`

**New Methods**:
- `initializeAutoLock()` - Start auto-lock monitoring
- `disposeAutoLock()` - Stop auto-lock monitoring
- `dispose()` - Cleanup when provider is destroyed

**Integration**:
```dart
// Initialize when user successfully authenticates
securityProvider.initializeAutoLock();

// Cleanup when leaving secured area
securityProvider.disposeAutoLock();
```

#### 3. AuthenticationWrapper
**Location**: `lib/main.dart`

**Purpose**: Reactive authentication routing

**Behavior**:
- Listens to `SecurityProvider` changes
- Automatically redirects based on authentication state
- No manual navigation needed

**States**:
```dart
isLoading          → SplashScreen
!isPinSet          → PinSetupScreen (via SplashScreen)
!isAuthenticated   → PinLoginScreen
isAuthenticated    → HomeScreen
```

#### 4. HomeScreen Integration
**Location**: `lib/features/home/presentation/home_screen.dart`

**Changes**:
- `initState()` - Initializes auto-lock after successful authentication
- `dispose()` - Cleans up auto-lock when screen is destroyed

## Configuration

### Lock Duration
Currently set to **2 seconds**. To change:

```dart
// In app_lifecycle_manager.dart initialization
AppLifecycleManager(
  lockDuration: Duration(seconds: 5), // Change to 5 seconds
  onShouldLock: onShouldLock,
)
```

### Lifecycle States Monitored
The following states trigger background time tracking:
- `AppLifecycleState.paused` - App in background
- `AppLifecycleState.inactive` - App temporarily inactive
- `AppLifecycleState.hidden` - App hidden (iOS)

## Testing

### Manual Testing Steps

1. **Basic Auto-Lock Test**
   ```
   1. Launch app and enter PIN
   2. Wait for home screen to load
   3. Press home button (minimize app)
   4. Wait 3 seconds
   5. Return to app
   ✓ Should see PIN login screen
   ```

2. **Quick Switch Test**
   ```
   1. Launch app and enter PIN
   2. Quickly switch to another app and back (< 2 seconds)
   ✓ Should remain authenticated
   ```

3. **Deep Navigation Test**
   ```
   1. Launch app and enter PIN
   2. Navigate to a folder
   3. Minimize app for 3+ seconds
   4. Return to app
   ✓ Should see PIN login screen
   ✓ After re-login, should return to home screen
   ```

4. **Phone Call Test**
   ```
   1. Launch app and enter PIN
   2. Receive/make a phone call (app goes inactive)
   3. End call after 3+ seconds
   ✓ Should require PIN re-entry
   ```

### Debug Logging
The feature includes debug prints for troubleshooting:

```
App went to background at: 2024-11-23 10:30:45.123
App in background for: 5 seconds
Auto-locking app due to inactivity
```

Enable in terminal while running:
```bash
flutter run --debug
```

## Platform Considerations

### iOS
- Uses `AppLifecycleState.hidden` in addition to `paused`
- Works with App Switcher
- Works with Control Center overlay

### Android
- Uses `AppLifecycleState.paused` primarily
- Works with Recent Apps screen
- Works with split-screen mode

### macOS/Desktop
- Uses standard lifecycle states
- May have different behavior due to window management
- Test thoroughly on desktop platforms

## Security Implications

### Strengths
✅ Automatic protection against unauthorized access  
✅ Works even if user forgets to manually lock  
✅ Protects during accidental exposure (e.g., showing screen to others)  
✅ No way to bypass once triggered  
✅ Works across all app screens

### Considerations
⚠️ 2 seconds may be too short for some users (configurable)  
⚠️ May interrupt workflow if frequently switching apps  
⚠️ Does not protect against device-level access (use device PIN/biometrics too)

## User Experience

### Pros
- Automatic security without user action
- Peace of mind when switching apps
- Protects privacy in shared device scenarios
- Fast re-authentication (just PIN entry)

### Cons
- May feel intrusive for power users
- Requires re-entry even for quick app switches > 2 seconds
- No grace period or "remember device" option

## Future Enhancements

### Possible Improvements
1. **Configurable Duration**
   - Settings screen to adjust auto-lock time
   - Options: Immediate, 5s, 10s, 30s, Never

2. **Biometric Quick Unlock**
   - Use fingerprint/face ID instead of PIN after auto-lock
   - Faster re-authentication

3. **Smart Lock**
   - Don't lock if user is actively using other apps
   - Different timeouts for different security levels

4. **Activity-Based Locking**
   - Lock immediately when viewing sensitive content
   - Longer timeout for general browsing

5. **Location-Based Auto-Lock**
   - Disable auto-lock when at trusted locations (home WiFi)
   - Enable stricter locking in public places

## Troubleshooting

### App Not Locking Automatically

**Check**:
1. `initializeAutoLock()` is called in HomeScreen.initState()
2. WidgetsBinding observer is properly registered
3. Debug logs show lifecycle state changes
4. Provider is not being recreated unexpectedly

**Solution**:
```dart
// Verify in debug console
debugPrint('Auto-lock initialized: ${lifecycleManager != null}');
```

### App Locks Too Quickly

**Cause**: Lifecycle states may fire more frequently on some devices

**Solution**: Increase lock duration
```dart
lockDuration: Duration(seconds: 5)
```

### App Doesn't Lock on Desktop

**Cause**: Desktop platforms have different lifecycle behavior

**Solution**: May need platform-specific handling
```dart
if (Platform.isIOS || Platform.isAndroid) {
  initializeAutoLock();
}
```

### Navigation Issues After Auto-Lock

**Cause**: Multiple navigation events conflicting

**Solution**: AuthenticationWrapper handles this automatically via Provider Consumer

## Code Examples

### Customize Lock Duration
```dart
// In SecurityProvider
void initializeAutoLock({Duration? customDuration}) {
  if (_lifecycleManager == null) {
    _lifecycleManager = AppLifecycleManager(
      lockDuration: customDuration ?? Duration(seconds: 2),
      onShouldLock: () {
        if (_isAuthenticated && isPinSet) {
          logout();
        }
      },
    );
    _lifecycleManager!.initialize();
  }
}
```

### Add Lock Event Listener
```dart
// In your screen
@override
void initState() {
  super.initState();
  final securityProvider = Provider.of<SecurityProvider>(context, listen: false);
  securityProvider.addListener(_onSecurityChanged);
}

void _onSecurityChanged() {
  if (!securityProvider.isAuthenticated) {
    // App was locked, cleanup sensitive data
    clearSensitiveData();
  }
}
```

## Performance Impact

### Memory
- Minimal: Single observer instance
- Cleaned up automatically on dispose

### CPU
- Negligible: Only processes lifecycle events
- No continuous background processing

### Battery
- No impact: Native lifecycle callbacks
- No timers or polling

## Compatibility

- ✅ Flutter 3.0+
- ✅ iOS 12+
- ✅ Android 6.0+ (API 23+)
- ✅ macOS 10.14+
- ✅ Web (with limitations)
- ✅ Windows/Linux (with testing)

## Related Features

- [PIN Security System](SECURITY_FEATURE.md#pin-security-system)
- [Manual Lock Button](SECURITY_FEATURE.md#app-locking)
- [Media Hiding](SECURITY_FEATURE.md#media-gallery-hiding)

## Support

For issues specific to auto-lock:
1. Check debug logs for lifecycle events
2. Verify initialization in appropriate screens
3. Test lock duration timing
4. Confirm Provider state management
5. Review platform-specific behavior

---

**Last Updated**: November 23, 2025  
**Feature Version**: 1.0  
**Tested Platforms**: iOS, Android
