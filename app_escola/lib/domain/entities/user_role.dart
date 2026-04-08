/// Valores de `role` em `usuarios/{uid}` conforme especificação técnica
/// (`admin` | `colab`).
enum UserRole {
  admin,
  colab,
}

UserRole? parseUserRole(String? raw) {
  switch (raw) {
    case 'admin':
      return UserRole.admin;
    case 'colab':
      return UserRole.colab;
    default:
      return null;
  }
}

extension UserRoleLabel on UserRole {
  String get firestoreValue => switch (this) {
        UserRole.admin => 'admin',
        UserRole.colab => 'colab',
      };
}
