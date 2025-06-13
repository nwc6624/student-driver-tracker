import 'package:flutter/material.dart';

class AppTheme {
  // Background images
  static const String lightBackground = 'assets/images/light_background.png';
  static const String darkBackground = 'assets/images/dark_background.png';

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.transparent,
    extensions: <ThemeExtension<dynamic>>[
      AppThemeExtension(
        backgroundImage: lightBackground,
      ),
    ],
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    extensions: <ThemeExtension<dynamic>>[
      AppThemeExtension(
        backgroundImage: darkBackground,
      ),
    ],
  );

  // Get the appropriate background image based on theme mode
  static String getBackgroundImage(ThemeMode mode) {
    return mode == ThemeMode.dark ? darkBackground : lightBackground;
  }
}

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final String backgroundImage;

  const AppThemeExtension({
    required this.backgroundImage,
  });

  @override
  @override
  ThemeExtension<AppThemeExtension> copyWith({
    String? backgroundImage,
  }) {
    return AppThemeExtension(
      backgroundImage: backgroundImage ?? this.backgroundImage,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      backgroundImage: backgroundImage,
    );
  }
}
