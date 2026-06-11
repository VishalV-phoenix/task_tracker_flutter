// =============================================
// SETTINGS_PROVIDER.DART
// Manages user settings state
// Fixed: Dark mode now properly changes all colors
// =============================================

import 'package:flutter/material.dart';
import '../database/settings_dao.dart';
import '../models/settings_model.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsDao _dao = SettingsDao();

  SettingsModel _settings = SettingsModel();
  bool _isLoading = false;

  SettingsModel get settings => _settings;
  bool get isLoading => _isLoading;

  String get theme => _settings.theme;
  String get finalGoal => _settings.finalGoal;
  double get defaultNotifyBefore => _settings.defaultNotifyBefore;
  int get autoArchiveDays => _settings.autoArchiveDays;
  bool get notificationsEnabled => _settings.notificationsEnabled;

  // Check if current theme is dark
  bool get isDarkMode {
    if (_settings.theme == 'dark') return true;
    if (_settings.theme == 'auto') {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return false;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _dao.get();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTheme(String theme) async {
    _settings = _settings.copyWith(theme: theme);
    notifyListeners();
    await _dao.update(_settings);
  }

  Future<void> updateFinalGoal(String goal) async {
    _settings = _settings.copyWith(finalGoal: goal);
    notifyListeners();
    await _dao.update(_settings);
  }

  Future<void> updateDefaultNotifyBefore(double hours) async {
    _settings = _settings.copyWith(defaultNotifyBefore: hours);
    notifyListeners();
    await _dao.update(_settings);
  }

  Future<void> updateAutoArchiveDays(int days) async {
    _settings = _settings.copyWith(autoArchiveDays: days);
    notifyListeners();
    await _dao.update(_settings);
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    notifyListeners();
    await _dao.update(_settings);
  }

  ThemeData getThemeData() {
    return isDarkMode ? _darkTheme() : _lightTheme();
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: Colors.white,
      dialogBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
        brightness: Brightness.dark,
        surface: const Color(0xFF1E293B),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xFF1E293B),
      dialogBackgroundColor: const Color(0xFF1E293B),
      // Force all text to be light in dark mode
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFF1F5F9)),
        bodyMedium: TextStyle(color: Color(0xFFF1F5F9)),
        bodySmall: TextStyle(color: Color(0xFFCBD5E1)),
        titleLarge: TextStyle(color: Color(0xFFF1F5F9)),
        titleMedium: TextStyle(color: Color(0xFFF1F5F9)),
        titleSmall: TextStyle(color: Color(0xFFCBD5E1)),
        labelLarge: TextStyle(color: Color(0xFFF1F5F9)),
        labelMedium: TextStyle(color: Color(0xFFCBD5E1)),
        labelSmall: TextStyle(color: Color(0xFF94A3B8)),
      ),
      iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: const Color(0xFF334155),
        filled: true,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        labelStyle: const TextStyle(color: Color(0xFFCBD5E1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
        ),
      ),
      dividerColor: const Color(0xFF334155),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: Color(0xFFF1F5F9)),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFFF1F5F9),
        iconColor: Color(0xFFF1F5F9),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(const Color(0xFF4F46E5)),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
    );
  }
}