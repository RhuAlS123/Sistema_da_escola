import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema escuro inspirado no protótipo ICPRO (Tailwind slate + blue-600).
class AppTheme {
  AppTheme._();

  /// Títulos de secção estilo ICPRO (`text-blue-400 uppercase` no React).
  static TextStyle sectionHeader(BuildContext context) {
    final base = Theme.of(context).textTheme.titleSmall ?? const TextStyle();
    return base.copyWith(
      color: const Color(0xFF60A5FA),
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
    );
  }

  static ThemeData darkIcpro() {
    const slate950 = Color(0xFF020617);
    const slate900 = Color(0xFF0F172A);
    const slate800 = Color(0xFF1E293B);
    const slate700 = Color(0xFF334155);
    const slate400 = Color(0xFF94A3B8);
    const slate300 = Color(0xFFCBD5E1);
    const slate100 = Color(0xFFF1F5F9);
    const blue600 = Color(0xFF2563EB);

    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: blue600,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF1E3A8A),
      onPrimaryContainer: const Color(0xFFBFDBFE),
      secondary: AppColors.accentRed,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF3D1515),
      onSecondaryContainer: const Color(0xFFF5D0D0),
      tertiary: AppColors.accentGreen,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFF0F2A1F),
      onTertiaryContainer: const Color(0xFFB8E0CF),
      error: const Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFECACA),
      surface: slate950,
      onSurface: slate100,
      onSurfaceVariant: slate400,
      outline: slate700,
      outlineVariant: const Color(0xFF1E293B),
      shadow: Colors.black,
      scrim: Color(0xCC000000),
      inverseSurface: slate100,
      onInverseSurface: slate900,
      inversePrimary: AppColors.primary,
      surfaceContainerHighest: slate800,
    );

    final baseText = ThemeData(brightness: Brightness.dark, useMaterial3: true)
        .textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: slate950,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: baseText.copyWith(
        headlineSmall: baseText.headlineSmall?.copyWith(
          color: slate100,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          color: slate100,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseText.titleMedium?.copyWith(color: slate100),
        titleSmall: baseText.titleSmall?.copyWith(color: slate300),
        bodyLarge: baseText.bodyLarge?.copyWith(color: slate300),
        bodyMedium: baseText.bodyMedium?.copyWith(color: slate300),
        bodySmall: baseText.bodySmall?.copyWith(color: slate400),
        labelLarge: baseText.labelLarge?.copyWith(color: slate400),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: slate900,
        foregroundColor: slate100,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: slate100,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: slate900,
        indicatorColor: blue600.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: slate100,
            );
          }
          return const TextStyle(fontSize: 12, color: slate400);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: slate100, size: 24);
          }
          return const IconThemeData(color: slate400, size: 24);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: slate900,
        indicatorColor: blue600.withValues(alpha: 0.4),
        selectedIconTheme: const IconThemeData(color: slate100),
        selectedLabelTextStyle: const TextStyle(
          color: slate100,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme: const IconThemeData(color: slate400),
        unselectedLabelTextStyle: const TextStyle(color: slate400),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: slate900,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: slate300,
          side: const BorderSide(color: slate700),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: blue600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate800,
        labelStyle: const TextStyle(color: slate400),
        floatingLabelStyle: const TextStyle(color: slate300),
        hintStyle: TextStyle(color: slate400.withValues(alpha: 0.85)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: slate700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: slate700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: blue600, width: 1.5),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: slate900,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: slate800,
        selectedColor: blue600.withValues(alpha: 0.35),
        labelStyle: const TextStyle(color: slate100, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: slate700),
      ),
      dividerTheme: const DividerThemeData(
        color: slate800,
        thickness: 1,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(slate800),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: slate900,
        headerForegroundColor: slate100,
        headerBackgroundColor: slate800,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return slate400;
          return slate100;
        }),
        todayForegroundColor: WidgetStatePropertyAll(blue600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: slate700),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: slate400,
        textColor: slate100,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: blue600,
      ),
    );
  }

  /// Tema claro legado (marca SIS Icpro).
  static ThemeData light() {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD6E4F2),
      onPrimaryContainer: const Color(0xFF0F2740),
      secondary: AppColors.accentRed,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFF2E4E4),
      onSecondaryContainer: const Color(0xFF3D1515),
      tertiary: AppColors.accentGreen,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFE3F0EA),
      onTertiaryContainer: const Color(0xFF0F2A1F),
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: const Color(0xFFF9DEDC),
      onErrorContainer: const Color(0xFF410E0B),
      surface: const Color(0xFFF8F9FB),
      onSurface: const Color(0xFF1B1B1F),
      onSurfaceVariant: const Color(0xFF44474E),
      outline: const Color(0xFFC4C6D0),
      outlineVariant: const Color(0xFFE1E2E8),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: const Color(0xFF2F3036),
      onInverseSurface: const Color(0xFFF1F0F7),
      inversePrimary: const Color(0xFFA8C8EC),
      surfaceContainerHighest: const Color(0xFFE8EAF0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        backgroundColor: Colors.white,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            );
          }
          return TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.primary, size: 24);
          }
          return IconThemeData(color: scheme.onSurfaceVariant, size: 24);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
