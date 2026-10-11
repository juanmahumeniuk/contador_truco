import 'package:flutter/material.dart';

/// Paleta inspirada en un paño verde de mesa de truco.
abstract final class TrucoColors {
  static const Color felt = Color(0xFF0C3B2A);
  static const Color feltLight = Color(0xFF14573E);
  static const Color panel = Color(0xFF0A2F22);
  static const Color gold = Color(0xFFF2C14E);
  static const Color wood = Color(0xFFF3E3BF);
  static const Color matchHead = Color(0xFFD9442B);
  static const Color ghost = Color(0x1FFFFFFF);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: TrucoColors.feltLight,
    brightness: Brightness.dark,
    primary: TrucoColors.gold,
    onPrimary: const Color(0xFF3A2A00),
    surface: TrucoColors.panel,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: TrucoColors.felt,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF123F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
