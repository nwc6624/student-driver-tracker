import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'background_provider.dart';

class ThemeProvider extends StateNotifier<ThemeMode> {
  ThemeProvider(this.ref) : super(ThemeMode.light);

  final Ref ref;

  void toggleTheme() {
    final newTheme = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newTheme;
    
    // Update background when theme changes
    ref.read(backgroundProvider.notifier).updateBackground(newTheme);
  }
}

final themeProvider = StateNotifierProvider<ThemeProvider, ThemeMode>((ref) {
  return ThemeProvider(ref);
});
