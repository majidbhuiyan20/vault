// lib/features/security/provider/security_provider.dart
import 'package:flutter/material.dart';
import '../models/security_settings.dart';
import '../services/security_service.dart';
import '../services/app_lifecycle_manager.dart';

class SecurityProvider with ChangeNotifier {
  final SecurityService _securityService;
  SecuritySettings? _settings;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  AppLifecycleManager? _lifecycleManager;

  SecurityProvider(this._securityService) {
    _initialize();
  }

  SecuritySettings? get settings => _settings;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isPinSet => _settings?.isPinSet ?? false;

  // Initialize lifecycle manager for auto-lock
  void initializeAutoLock() {
    if (_lifecycleManager == null) {
      _lifecycleManager = AppLifecycleManager(
        lockDuration: Duration(seconds: 2),
        onShouldLock: () {
          if (_isAuthenticated && isPinSet) {
            logout();
          }
        },
      );
      _lifecycleManager!.initialize();
    }
  }

  // Clean up lifecycle manager
  void disposeAutoLock() {
    _lifecycleManager?.dispose();
    _lifecycleManager = null;
  }

  @override
  void dispose() {
    disposeAutoLock();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      _settings = await _securityService.loadSecuritySettings();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing security: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set PIN for first time
  Future<bool> setPin(String pin, String confirmPin) async {
    if (pin != confirmPin) {
      return false;
    }

    if (pin.length < 4) {
      return false;
    }

    final success = await _securityService.setPin(pin);

    if (success) {
      _settings = await _securityService.loadSecuritySettings();
      _isAuthenticated = true;
      notifyListeners();
    }

    return success;
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    final isValid = await _securityService.verifyPin(pin);

    if (isValid) {
      _isAuthenticated = true;
      _settings = await _securityService.loadSecuritySettings();
      notifyListeners();
    }

    return isValid;
  }

  // Logout (lock the app)
  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  // Change PIN
  Future<bool> changePin(
    String oldPin,
    String newPin,
    String confirmNewPin,
  ) async {
    if (newPin != confirmNewPin) {
      return false;
    }

    if (newPin.length < 4) {
      return false;
    }

    final success = await _securityService.changePin(oldPin, newPin);

    if (success) {
      _settings = await _securityService.loadSecuritySettings();
      notifyListeners();
    }

    return success;
  }

  // Reset PIN (for testing)
  Future<void> resetPin() async {
    await _securityService.resetPin();
    _settings = await _securityService.loadSecuritySettings();
    _isAuthenticated = false;
    notifyListeners();
  }
}
