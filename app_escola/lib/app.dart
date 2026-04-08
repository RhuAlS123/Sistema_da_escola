import 'package:flutter/material.dart';

import 'core/branding/app_brand.dart';
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
      theme: AppTheme.light(),
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
