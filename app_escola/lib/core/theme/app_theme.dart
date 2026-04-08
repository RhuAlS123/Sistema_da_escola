import 'package:flutter/material.dart';

/// Tema base. Ajustes finos de tipografia/cores vêm nas fases de UI.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const seed = Color(0xFF1565C0);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
