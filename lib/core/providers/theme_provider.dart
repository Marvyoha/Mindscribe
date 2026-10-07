import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

/// Manages the active [ThemeMode]: Light, Dark, or System.
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeMode> {
  final StorageService _storage = StorageService();

  @override
  ThemeMode build() {
    _loadThemeMode();
    return ThemeMode.system;
  }

  Future<void> _loadThemeMode() async {
    final stored = await _storage.getThemeMode();
    final mode = _modeFromString(stored);
    if (mode != null) {
      state = mode;
    }
  }

  void setThemeMode(ThemeMode mode) {
    _storage.saveThemeMode(_modeToString(mode));
    state = mode;
  }

  void toggleTheme() {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
    };
    setThemeMode(next);
  }

  static String _modeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  static ThemeMode? _modeFromString(String? s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => null,
      };
}