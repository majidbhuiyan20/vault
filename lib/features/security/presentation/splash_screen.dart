// lib/features/security/presentation/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/security_provider.dart';
import 'pin_setup_screen.dart';
import 'pin_login_screen.dart';
import '../../home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for a brief moment to show splash
    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;

    final securityProvider = Provider.of<SecurityProvider>(
      context,
      listen: false,
    );

    // Wait for initialization to complete
    while (securityProvider.isLoading) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    if (!mounted) return;

    // Determine which screen to show
    Widget nextScreen;

    if (!securityProvider.isPinSet) {
      // First time user - show PIN setup
      nextScreen = PinSetupScreen();
    } else if (!securityProvider.isAuthenticated) {
      // PIN is set but not authenticated - show login
      nextScreen = PinLoginScreen();
    } else {
      // Already authenticated - go to home
      nextScreen = HomeScreen();
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4361EE).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.folder_special_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 32),

            // App Name
            Text(
              'Secure Vault',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Your Private Media Locker',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),

            SizedBox(height: 48),

            // Loading Indicator
            CircularProgressIndicator(color: Color(0xFF4361EE)),
          ],
        ),
      ),
    );
  }
}
