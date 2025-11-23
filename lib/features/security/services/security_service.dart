// lib/features/security/services/security_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/security_settings.dart';

class SecurityService {
  static const String _securityKey = 'security_settings';

  // Hash PIN using SHA256
  String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Save security settings
  Future<void> saveSecuritySettings(SecuritySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(settings.toJson());
    await prefs.setString(_securityKey, jsonString);
  }

  // Load security settings
  Future<SecuritySettings> loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_securityKey);

    if (jsonString == null) {
      return SecuritySettings(isPinSet: false);
    }

    final jsonData = json.decode(jsonString);
    return SecuritySettings.fromJson(jsonData);
  }

  // Set new PIN
  Future<bool> setPin(String pin) async {
    try {
      if (pin.length < 4) {
        return false;
      }

      final hashedPin = hashPin(pin);
      final settings = SecuritySettings(
        isPinSet: true,
        hashedPin: hashedPin,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
      );

      await saveSecuritySettings(settings);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final settings = await loadSecuritySettings();

      if (!settings.isPinSet || settings.hashedPin == null) {
        return false;
      }

      final hashedPin = hashPin(pin);
      final isValid = hashedPin == settings.hashedPin;

      if (isValid) {
        // Update last accessed time
        final updatedSettings = settings.copyWith(
          lastAccessedAt: DateTime.now(),
        );
        await saveSecuritySettings(updatedSettings);
      }

      return isValid;
    } catch (e) {
      return false;
    }
  }

  // Check if PIN is set
  Future<bool> isPinSet() async {
    final settings = await loadSecuritySettings();
    return settings.isPinSet;
  }

  // Reset PIN (for testing or reset functionality)
  Future<void> resetPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_securityKey);
  }

  // Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      // Verify old PIN first
      final isValid = await verifyPin(oldPin);
      if (!isValid) {
        return false;
      }

      // Set new PIN
      return await setPin(newPin);
    } catch (e) {
      return false;
    }
  }
}
