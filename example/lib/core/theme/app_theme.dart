import 'package:flutter/material.dart';

/// Application theme and styling configuration
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Color scheme
  static const Color onlineColor = Colors.green;
  static const Color offlineColor = Colors.red;
  static const Color playingColor = Colors.green;
  static const Color pausedColor = Colors.orange;
  static const Color stoppedColor = Colors.red;
  static const Color transitioningColor = Colors.blue;
  static const Color noMediaColor = Colors.grey;
  
  // Media type colors
  static const Color videoColor = Colors.red;
  static const Color audioColor = Colors.blue;
  static const Color imageColor = Colors.green;
  static const Color unknownMediaColor = Colors.grey;

  AppTheme._();
}
