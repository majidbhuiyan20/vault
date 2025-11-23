// lib/features/security/services/app_lifecycle_manager.dart
import 'package:flutter/material.dart';

class AppLifecycleManager with WidgetsBindingObserver {
  DateTime? _backgroundTime;
  final Duration lockDuration;
  final VoidCallback onShouldLock;

  AppLifecycleManager({required this.lockDuration, required this.onShouldLock});

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App went to background
        _backgroundTime = DateTime.now();
        debugPrint('App went to background at: $_backgroundTime');
        break;

      case AppLifecycleState.resumed:
        // App came to foreground
        if (_backgroundTime != null) {
          final timeInBackground = DateTime.now().difference(_backgroundTime!);
          debugPrint(
            'App in background for: ${timeInBackground.inSeconds} seconds',
          );

          if (timeInBackground >= lockDuration) {
            debugPrint('Auto-locking app due to inactivity');
            onShouldLock();
          }
          _backgroundTime = null;
        }
        break;

      case AppLifecycleState.detached:
        // App is detached
        break;
    }
  }
}
