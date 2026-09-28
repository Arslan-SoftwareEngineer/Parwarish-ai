import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppColorScheme {
  orange,
  blue,
  green,
  purple,
  pink,
}

class ThemeService {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  static const String keyThemeMode = 'app_theme_mode'; // 'system' | 'light' | 'dark'
  static const String keyColorScheme = 'app_color_scheme'; // 'orange', 'blue', 'green', 'purple', 'pink'
  static const String keyFontScale = 'app_font_scale'; // 1.0, 1.15, 1.3

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  final ValueNotifier<AppColorScheme> colorSchemeNotifier = ValueNotifier<AppColorScheme>(AppColorScheme.orange);
  final ValueNotifier<double> fontScaleNotifier = ValueNotifier<double>(1.0);

  ThemeMode get currentThemeMode => themeModeNotifier.value;
  AppColorScheme get currentColorScheme => colorSchemeNotifier.value;
  double get currentFontScale => fontScaleNotifier.value;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Theme Mode
    final modeStr = prefs.getString(keyThemeMode) ?? 'system';
    switch (modeStr) {
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 'dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeModeNotifier.value = ThemeMode.system;
        break;
    }

    // Color Scheme
    final schemeStr = prefs.getString(keyColorScheme) ?? 'orange';
    switch (schemeStr) {
      case 'blue':
        colorSchemeNotifier.value = AppColorScheme.blue;
        break;
      case 'green':
        colorSchemeNotifier.value = AppColorScheme.green;
        break;
      case 'purple':
        colorSchemeNotifier.value = AppColorScheme.purple;
        break;
      case 'pink':
        colorSchemeNotifier.value = AppColorScheme.pink;
        break;
      case 'orange':
      default:
        colorSchemeNotifier.value = AppColorScheme.orange;
        break;
    }

    // Font Scale
    final scale = prefs.getDouble(keyFontScale) ?? 1.0;
    fontScaleNotifier.value = scale;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await prefs.setString(keyThemeMode, modeStr);
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    colorSchemeNotifier.value = scheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyColorScheme, scheme.name);
  }

  Future<void> setFontScale(double scale) async {
    fontScaleNotifier.value = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyFontScale, scale);
  }
}
