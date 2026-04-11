import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/app_brand.dart';
import '../../core/layout/app_breakpoints.dart';
import '../../domain/domain.dart';
import '../providers/app_providers.dart';
import '../shell/app_main_shell.dart';
import '../shell/app_navigation.dart';

String _roleLabel(UserRole role) {
  return switch (role) {
    UserRole.admin => 'Administrador',
    UserRole.colab => 'Colaborador',
  };
}

/// Layout pós-login: sidebar estilo ICPRO (desktop) ou drawer (mobile).
class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final wide = !AppBreakpoints.isMobileWidth(MediaQuery.sizeOf(context).width);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
          return Scaffold(
            body: _MissingProfileMessage(firebaseUid: uid),
          );
        }

        if (wide) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IcproSidebar(profile: profile),
                const Expanded(child: AppMainShellBody()),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    kLogoAssetPath,
                    height: 26,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.school_outlined,
                      size: 26,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    kAppDisplayName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Sair',
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          drawer: Drawer(
            child: _IcproSidebar(
              profile: profile,
              closeDrawerOnSelect: true,
            ),
          ),
          body: const AppMainShellBody(),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: _ProfileErrorBody(message: e.toString()),
      ),
    );
  }
}

class _IcproSidebar extends ConsumerWidget {
  const _IcproSidebar({
    required this.profile,
    this.closeDrawerOnSelect = false,
  });

  final AppUserProfile profile;
  final bool closeDrawerOnSelect;

  static const _slate800 = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const sidebarBg = Color(0xFF0F172A);
    const border = _slate800;
    final index = clampNavIndex(ref.watch(mainTabIndexProvider));
    final selectedStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );
    final idleStyle = TextStyle(
      color: const Color(0xFF94A3B8),
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );

    void select(int i) {
      ref.read(mainTabIndexProvider.notifier).state = i;
      if (closeDrawerOnSelect && context.mounted) {
        Navigator.of(context).pop();
      }
    }

    return Material(
      color: sidebarBg,
      child: SafeArea(
        child: SizedBox(
          width: 264,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        kLogoAssetPath,
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.school_outlined,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        kAppDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: border, height: 1),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < kAppNavDestinos.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Material(
                    color: i == index
                        ? const Color(0xFF2563EB)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => select(i),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              kAppNavDestinos[i].icon,
                              size: 22,
                              color: i == index
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                kAppNavDestinos[i].label,
                                style: i == index ? selectedStyle : idleStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: border, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF334155),
                      child: Text(
                        profile.nome.isNotEmpty
                            ? profile.nome.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _roleLabel(profile.role),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!closeDrawerOnSelect)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: TextButton.icon(
                    onPressed: () =>
                        ref.read(authRepositoryProvider).signOut(),
                    icon: const Icon(
                      Icons.logout,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                    label: const Text(
                      'Sair',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
