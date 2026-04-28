import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/theme/app_theme.dart';

class CustomTheme {
  static ThemeData darkTheme() {
    return AppTheme.darkTheme;
  }

  static ThemeData lightTheme() {
    return AppTheme.lightTheme;
  }

  static ThemeData customTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.purple,
        brightness: Brightness.dark,
      ),
    );
  }
}
