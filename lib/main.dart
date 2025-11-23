// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/folder_content/service/media_storage_service.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/home/provider/home_provider.dart';
import 'features/folder_content/provider/media_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(
          create: (_) => MediaProvider(MediaStorageService()),
        ),
      ],
      child: MaterialApp(
        title: 'Secure Vault',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Color(0xFF0F0F1E),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
        ),
        home: HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}