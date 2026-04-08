import 'user_role.dart';

/// Documento `usuarios/{uid}` no Firestore: campos `nome` e `role`
/// conforme modelo descrito na especificação.
class AppUserProfile {
  const AppUserProfile({
    required this.nome,
    required this.role,
  });

  final String nome;
  final UserRole role;

  static AppUserProfile? fromFirestoreMap(Map<String, dynamic> data) {
    final nome = data['nome'];
    final roleRaw = data['role'];
    if (nome is! String || nome.isEmpty) return null;
    final role = parseUserRole(
      roleRaw is String ? roleRaw : null,
    );
    if (role == null) return null;
    return AppUserProfile(nome: nome, role: role);
  }
}
