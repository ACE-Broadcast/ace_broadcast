import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _useDynamicColor = false;
  ThemeMode _themeMode = ThemeMode.system;

  bool get useDynamicColor => _useDynamicColor;
  ThemeMode get themeMode => _themeMode;

  void toggleDynamicColor() {
    _useDynamicColor = !_useDynamicColor;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
