import 'package:flutter/material.dart';

abstract final class PathsTheme {
  static const background = Color(0xFFF5FBFF),
      ink = Color(0xFF101418),
      blue = Color(0xFF147DCE),
      aqua = Color(0xFFC4F2F3);
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(seedColor: blue, surface: background),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'LilitaOne',
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF050708),
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
    ),
  );
}
