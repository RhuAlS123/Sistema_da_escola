import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/fixed_auth_mapping.dart';
import '../../core/branding/app_brand.dart';
import '../../core/errors/app_error_messages.dart';
import '../providers/app_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _passwordController = TextEditingController();
  FixedAccount _account = FixedAccount.colaborador1;
  bool _loading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Informe a senha.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
            email: _account.authEmail,
            password: password,
          );
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('[Auth] code=${e.code} message=${e.message}');
      }
      setState(() {
        _errorMessage = _mapAuthError(e);
        _loading = false;
      });
      return;
    } catch (e) {
      setState(() {
        _errorMessage = mensagemErroParaUsuario(e);
        _loading = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  static String _mapAuthError(FirebaseAuthException e) {
    final suffix = kDebugMode ? ' (código: ${e.code})' : '';
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail inválido (verifique o cadastro no Firebase).$suffix';
      case 'user-disabled':
        return 'Usuário desativado.$suffix';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Senha não confere com o cadastro no Firebase Authentication, '
            'ou o e-mail não existe. No Console, confira o usuário ou use '
            '"Redefinir senha" / exclua e crie de novo com a senha do escopo '
            '(confira o utilizador no Console e a coleção usuarios no Firestore; ver README).$suffix';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente de novo.$suffix';
      case 'network-request-failed':
        return 'Sem conexão ou rede instável. Verifique e tente de novo.$suffix';
      default:
        return '${e.message ?? 'Erro de autenticação'} (${e.code})$suffix';
    }
  }

  @override
  Widget build(BuildContext context) {
    const slate900 = Color(0xFF0F172A);
    const slate800 = Color(0xFF1E293B);
    const slate700 = Color(0xFF334155);
    const blue600 = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: slate900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: slate800),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 100),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: slate700.withValues(alpha: 0.85),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: blue600.withValues(alpha: 0.08),
                              blurRadius: 24,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          kLogoAssetPath,
                          height: 88,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Sistema de cadastro',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFFF1F5F9),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      kAppDisplayName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF94A3B8),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestão de alunos e financeiro',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Usuário',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF94A3B8),
                          ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<FixedAccount>(
                      // ignore: deprecated_member_use
                      value: _account,
                      dropdownColor: slate800,
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: slate800,
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
                          borderSide:
                              const BorderSide(color: blue600, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      items: FixedAccount.values
                          .map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Text(a.label),
                            ),
                          )
                          .toList(),
                      onChanged: _loading
                          ? null
                          : (v) {
                              if (v != null) setState(() => _account = v);
                            },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Conta no Firebase: ${_account.authEmail}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Projeto Firebase: ${Firebase.app().options.projectId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF475569),
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Senha',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF94A3B8),
                          ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Color(0xFFF1F5F9)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: slate800,
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
                          borderSide:
                              const BorderSide(color: blue600, width: 1.5),
                        ),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Mostrar' : 'Ocultar',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF94A3B8),
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _loading ? null : _submit(),
                      enabled: !_loading,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7F1D1D).withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFF87171).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFFECACA),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: blue600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        shadowColor: blue600.withValues(alpha: 0.45),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
