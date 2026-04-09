/// Contas fixas do escopo (nomes e papéis vêm da especificação).
///
/// O Firebase Auth com **e-mail e senha** exige um e-mail único por usuário.
/// A especificação não define e-mails; usa-se **mapeamento interno** usuário → e-mail.
/// Os valores abaixo são esse mapeamento: cadastre **os mesmos e-mails** no console
/// (ver secção Firebase deste README). As senhas continuam sendo as do documento de escopo
/// (digitadas no login), **não** armazenadas no código.
enum FixedAccount {
  colaborador1,
  colaborador2,
  administrador,
}

extension FixedAccountX on FixedAccount {
  /// Rótulo exibido no login (texto do escopo).
  String get label => switch (this) {
        FixedAccount.colaborador1 => 'Colaborador 1',
        FixedAccount.colaborador2 => 'Colaborador 2',
        FixedAccount.administrador => 'Administrador',
      };

  /// E-mail usado apenas para Firebase Auth. Deve existir no console com a
  /// senha correspondente do escopo.
  /// Alinhado aos usuários criados no Firebase Authentication (mesmos e-mails).
  String get authEmail => switch (this) {
        FixedAccount.colaborador1 => 'colab1@escola.com',
        FixedAccount.colaborador2 => 'colab2@escola.com',
        FixedAccount.administrador => 'admin@escola.com',
      };
}
