import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller pour gérer le thème de l'application
class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  
  bool _isDarkMode = false;

  ThemeController() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  /// Charge la préférence de thème sauvegardée
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement du thème: $e');
    }
  }

  /// Bascule le mode sombre
  Future<void> toggleDarkMode() async {
    try {
      _isDarkMode = !_isDarkMode;
      debugPrint('🌙 Toggle Dark Mode → $_isDarkMode');
      notifyListeners(); // Notifier immédiatement pour UI instantanée
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      debugPrint('💾 Saved to SharedPreferences: $_isDarkMode');
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde du thème: $e');
    }
  }

  /// Force le mode clair
  Future<void> setLightMode() async {
    if (!_isDarkMode) return;
    try {
      _isDarkMode = false;
      notifyListeners(); // Notifier immédiatement
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, false);
    } catch (e) {
      debugPrint('Erreur lors du changement de thème: $e');
    }
  }

  /// Force le mode sombre
  Future<void> setDarkMode() async {
    if (_isDarkMode) return;
    try {
      _isDarkMode = true;
      notifyListeners(); // Notifier immédiatement
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, true);
    } catch (e) {
      debugPrint('Erreur lors du changement de thème: $e');
    }
  }
}
