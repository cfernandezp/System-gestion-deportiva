import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DataSource local para persistencia de tema via SharedPreferences
/// RN-003: La preferencia se guarda localmente, no requiere conexion a internet
abstract class ThemeLocalDataSource {
  /// Lee el ThemeMode guardado
  Future<ThemeMode> getThemeMode();

  /// Guarda el ThemeMode seleccionado
  Future<void> saveThemeMode(ThemeMode mode);
}

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  static const String _themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;

  ThemeLocalDataSourceImpl({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<ThemeMode> getThemeMode() async {
    final value = _prefs.getString(_themeModeKey);
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        // RN-001: Por defecto sigue al sistema operativo
        return ThemeMode.system;
    }
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    final String value;
    switch (mode) {
      case ThemeMode.dark:
        value = 'dark';
      case ThemeMode.light:
        value = 'light';
      case ThemeMode.system:
        value = 'system';
    }
    await _prefs.setString(_themeModeKey, value);
  }
}
