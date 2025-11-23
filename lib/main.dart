// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/folder_content/service/media_storage_service.dart';
import 'features/home/provider/home_provider.dart';
import 'features/folder_content/provider/media_provider.dart';
import 'features/security/services/security_service.dart';
import 'features/security/provider/security_provider.dart';
import 'features/security/presentation/splash_screen.dart';
import 'features/security/presentation/pin_login_screen.dart';
import 'features/home/presentation/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Security Provider
        ChangeNotifierProvider(
          create: (_) => SecurityProvider(SecurityService()),
        ),

        // Home Provider
        ChangeNotifierProvider(create: (_) => HomeProvider()),

        // Media Provider
        ChangeNotifierProxyProvider<HomeProvider, MediaProvider>(
          create: (context) => MediaProvider(MediaStorageService()),
          update: (context, homeProvider, mediaProvider) {
            mediaProvider?.setHomeProvider(homeProvider);
            return mediaProvider!;
          },
        ),
      ],
      child: Consumer<SecurityProvider>(
        builder: (context, securityProvider, child) {
          return MaterialApp(
            title: 'Secure Vault',
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Color(0xFF0F0F1E),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
              ),
            ),
            home: AuthenticationWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, securityProvider, child) {
        if (securityProvider.isLoading) {
          return SplashScreen();
        }

        // If PIN not set, go to splash which will show setup
        if (!securityProvider.isPinSet) {
          return SplashScreen();
        }

        // If not authenticated, show login
        if (!securityProvider.isAuthenticated) {
          return PinLoginScreen();
        }

        // Authenticated, show home
        return HomeScreen();
      },
    );
  }
}
