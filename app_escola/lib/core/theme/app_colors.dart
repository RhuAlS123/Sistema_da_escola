import 'package:flutter/material.dart';

/// Cores alinhadas à marca SIS Icpro (azul PRO, vermelho IC, verde do símbolo),
/// com tons contidos para interface sóbria (evita vermelho/azul puro em excesso).
class AppColors {
  AppColors._();

  /// Azul institucional (referência ao “PRO” da logo).
  static const Color primary = Color(0xFF1B3A5C);

  /// Vermelho suave para acentos (referência ao “IC”) — não usar como fundo amplo.
  static const Color accentRed = Color(0xFFA63D3D);

  /// Verde discreto (referência ao ícone) — sucesso / detalhes.
  static const Color accentGreen = Color(0xFF2F6B52);

  static const Color surfaceTint = Color(0x0F1B3A5C);
}
