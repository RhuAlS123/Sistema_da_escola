import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/branding/app_brand.dart';
import 'core/format/app_formats.dart';
import 'core/layout/app_breakpoints.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/auth_gate.dart';

class AppEscola extends StatelessWidget {
  const AppEscola({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppDisplayName,
      debugShowCheckedModeBanner: false,
      locale: kAppLocale,
      supportedLocales: const [kAppLocale],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.darkIcpro(),
      home: const AuthGate(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context).clamp(
              minScaleFactor: AppBreakpoints.minTextScale,
              maxScaleFactor: AppBreakpoints.maxTextScale,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
