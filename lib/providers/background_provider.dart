import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackgroundProvider extends StateNotifier<String?> {
  BackgroundProvider() : super(null) {
    _selectRandomBackground(ThemeMode.light);
  }

  final List<String> _lightBackgrounds = [
    'assets/images/backgrounds/light/lightCity.png',
    'assets/images/backgrounds/light/lightLA.png',
    'assets/images/backgrounds/light/lightSeattle.png',
    'assets/images/backgrounds/light/lightCoast.png',
    'assets/images/backgrounds/light/lightMexico.png',
    'assets/images/backgrounds/light/lightSouthwest.png',
  ];

  final List<String> _darkBackgrounds = [
    'assets/images/backgrounds/dark/darkCity.png',
    'assets/images/backgrounds/dark/darkLA.png',
    'assets/images/backgrounds/dark/darkSeattle.png',
    'assets/images/backgrounds/dark/darkCoast.png',
    'assets/images/backgrounds/dark/darkMexico.png',
    'assets/images/backgrounds/dark/DarkSouthwest.png',
  ];

  void _selectRandomBackground(ThemeMode themeMode) {
    final random = Random();
    final backgrounds = themeMode == ThemeMode.light 
        ? _lightBackgrounds 
        : _darkBackgrounds;
    
    if (backgrounds.isNotEmpty) {
      final randomIndex = random.nextInt(backgrounds.length);
      state = backgrounds[randomIndex];
    } else {
      // Fallback to null if no backgrounds available
      state = null;
    }
  }

  void updateBackground(ThemeMode themeMode) {
    _selectRandomBackground(themeMode);
  }

  void refreshBackground(ThemeMode themeMode) {
    _selectRandomBackground(themeMode);
  }

  // Get fallback color when no background image is available
  Color getFallbackColor(ThemeMode themeMode) {
    final random = Random();
    if (themeMode == ThemeMode.light) {
      final lightColors = [
        const Color(0xFFF5F5DC), // Beige
        const Color(0xFFF0F8FF), // Alice Blue
        const Color(0xFFF5F5F5), // White Smoke
        const Color(0xFFFAF0E6), // Linen
        const Color(0xFFFDF5E6), // Old Lace
      ];
      return lightColors[random.nextInt(lightColors.length)];
    } else {
      final darkColors = [
        const Color(0xFF2F2F2F), // Dark Gray
        const Color(0xFF1A1A1A), // Very Dark Gray
        const Color(0xFF2D2D2D), // Charcoal
        const Color(0xFF1E1E1E), // Dark Slate
        const Color(0xFF2B2B2B), // Dark Charcoal
      ];
      return darkColors[random.nextInt(darkColors.length)];
    }
  }
}

final backgroundProvider = StateNotifierProvider<BackgroundProvider, String?>((ref) {
  return BackgroundProvider();
}); 