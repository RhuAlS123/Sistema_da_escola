import 'package:flutter/material.dart';

import '../../core/branding/app_brand.dart';
import '../../core/layout/app_breakpoints.dart';

/// Exibida quando o Firebase não inicializou (stub de credenciais ou falha).
class FirebaseRequiredPage extends StatelessWidget {
  const FirebaseRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = AppBreakpoints.isMobileWidth(width);

    return Scaffold(
      appBar: AppBar(title: const BrandedAppBarTitle(compact: true)),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: isMobile ? 56 : 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Firebase não disponível',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Configure as credenciais do seu projeto: em app_escola, siga '
                  'SETUP_FIREBASE.md e execute `flutterfire configure` para '
                  'gerar lib/firebase_options.dart.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
