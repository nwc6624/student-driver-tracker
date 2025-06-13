import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeProvider extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  
  ThemeProvider(this._prefs) : super(_prefs.getString('theme_mode') == 'dark' 
      ? ThemeMode.dark 
      : ThemeMode.light);

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode(state);
  }

  void _saveThemeMode(ThemeMode mode) {
    _prefs.setString('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  static final provider = StateNotifierProvider<ThemeProvider, ThemeMode>((ref) {
    return ThemeProvider(ref.watch(sharedPreferencesProvider));
  });
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});
