import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta fornecida
  static const _primary = Color(0xFF30A554); // destaque
  static const _primaryDark = Color(0xFF002E0F);
  static const _secondary = Color(0xFF386C5F);
  static const _tertiary = Color(0xFF9FB540);
  static const _neutral = Color(0xFF9FAFA1);
  static const _warn = Color(0xFFF9F871);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.light,
        primary: _primary,
        secondary: _secondary,
        tertiary: _tertiary,
        surface: Colors.white,
        onPrimary: Colors.white,
      ),
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF7F8F7),
      textTheme: textTheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        color: WidgetStatePropertyAll(_warn.withOpacity(.25)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
    );
  }
}
