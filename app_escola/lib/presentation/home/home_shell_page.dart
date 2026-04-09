import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/app_brand.dart';
import '../../core/layout/app_breakpoints.dart';
import '../../domain/domain.dart';
import '../providers/app_providers.dart';
import '../shell/app_main_shell.dart';

/// Área pós-login até as guias (Cadastro geral, Financeiro, etc.) existirem.
class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({super.key});

  static String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.admin => 'Administrador',
      UserRole.colab => 'Colaborador',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final wide = !AppBreakpoints.isMobileWidth(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            final uid =
                ref.watch(authStateProvider).valueOrNull?.uid ?? '';
            return _MissingProfileMessage(firebaseUid: uid);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Olá, ${profile.nome}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Chip(
                        label: Text(_roleLabel(profile.role)),
                      ),
                    ],
                  ),
                ),
              ),
              const Expanded(child: AppMainShellBody()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ProfileErrorBody(message: e.toString()),
      ),
      bottomNavigationBar: profileAsync.maybeWhen(
        data: (p) => p != null && !wide ? const AppMainBottomNav() : null,
        orElse: () => null,
      ),
    );
  }
}

class _ProfileErrorBody extends StatelessWidget {
  const _ProfileErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isPermission = message.contains('permission-denied');
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPermission ? Icons.lock_outline : Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                isPermission
                    ? 'Firestore bloqueou a leitura do perfil'
                    : 'Erro ao carregar perfil',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SelectableText(
                isPermission
                    ? 'O login funcionou, mas as regras de segurança do Firestore '
                        'não permitem ler usuarios/{seu uid}. Abra o Firebase → '
                        'Firestore → Regras e publique as regras do arquivo '
                        'app_escola/firestore.rules (ver README em app_escola).'
                    : message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingProfileMessage extends StatelessWidget {
  const _MissingProfileMessage({required this.firebaseUid});

  final String firebaseUid;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Documento ausente em Firestore',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Crie na coleção usuarios um documento cujo ID seja exatamente o '
                'seu UID (abaixo), com os campos nome (texto) e role (admin ou '
                'colab). Instruções no README em app_escola.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (firebaseUid.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Seu UID (ID do documento):',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  firebaseUid,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
