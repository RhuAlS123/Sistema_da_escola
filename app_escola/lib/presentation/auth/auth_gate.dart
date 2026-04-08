import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/app_firebase.dart';
import '../home/firebase_required_page.dart';
import '../providers/app_providers.dart';
import 'login_page.dart';
import '../home/home_shell_page.dart';

/// Só usa Firebase Auth depois de [appFirebaseInitialized] (evita crash em testes
/// que não chamam [initializeAppFirebase]).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!appFirebaseInitialized) {
      return const FirebaseRequiredPage();
    }

    final session = ref.watch(authStateProvider);

    return session.when(
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }
        return const HomeShellPage();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              'Erro ao observar sessão: $err',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
