import 'package:flutter/material.dart';

import '../repositories/hydration_repository.dart';

/// Persists and exposes the user's preferred [ThemeMode].
class ThemeProvider extends ChangeNotifier {
  /// Creates a theme controller backed by [repository].
  ThemeProvider({HydrationRepository? repository})
      : _repository = repository ?? HydrationRepository() {
    _themeMode = _repository.loadThemeMode();
  }

  final HydrationRepository _repository;

  late ThemeMode _themeMode;

  /// Current theme preference.
  ThemeMode get themeMode => _themeMode;

  /// Updates and persists [mode].
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _repository.saveThemeMode(mode);
  }
}
