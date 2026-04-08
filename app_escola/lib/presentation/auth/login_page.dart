import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/fixed_auth_mapping.dart';
import '../../core/branding/app_brand.dart';
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
        _errorMessage = 'Não foi possível entrar: $e';
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
            '(ver SETUP_USUARIOS.md).$suffix';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente de novo.$suffix';
      default:
        return '${e.message ?? 'Erro de autenticação'} (${e.code})$suffix';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(compact: true),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Entrar',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // value controla a seleção atual; initialValue não serve após mudanças.
                DropdownButtonFormField<FixedAccount>(
                  // ignore: deprecated_member_use
                  value: _account,
                  decoration: const InputDecoration(
                    labelText: 'Usuário',
                    border: OutlineInputBorder(),
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Projeto Firebase: ${Firebase.app().options.projectId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _loading ? null : _submit(),
                  enabled: !_loading,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
