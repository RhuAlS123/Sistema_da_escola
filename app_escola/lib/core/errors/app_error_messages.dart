import 'package:firebase_auth/firebase_auth.dart';

/// Texto para [SnackBar], [SelectableText] ou diálogos — prioriza rede e códigos Firebase.
String mensagemErroParaUsuario(Object erro) {
  if (erro is FirebaseAuthException) {
    return _authMensagem(erro);
  }
  if (erro is FirebaseException) {
    return _firebaseMensagem(erro);
  }
  final s = erro.toString();
  if (s.length > 220) {
    return '${s.substring(0, 217)}…';
  }
  return s;
}

String _authMensagem(FirebaseAuthException e) {
  switch (e.code) {
    case 'network-request-failed':
      return 'Sem conexão ou rede instável. Verifique e tente de novo.';
    case 'too-many-requests':
      return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
    case 'invalid-email':
      return 'E-mail inválido.';
    case 'user-disabled':
      return 'Esta conta foi desativada.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Senha ou usuário incorretos.';
    default:
      return e.message?.trim().isNotEmpty == true
          ? '${e.message} (${e.code})'
          : 'Erro de autenticação (${e.code}).';
  }
}

String _firebaseMensagem(FirebaseException e) {
  switch (e.code) {
    case 'permission-denied':
      return 'Sem permissão para esta operação. Verifique login e regras do Firestore.';
    case 'unavailable':
      return 'Serviço indisponível. Verifique a rede e tente de novo.';
    case 'deadline-exceeded':
      return 'Tempo esgotado. Tente novamente.';
    case 'resource-exhausted':
      return 'Limite temporário atingido. Tente mais tarde.';
    case 'failed-precondition':
      return 'Não foi possível concluir. Tente de novo.';
    case 'aborted':
      return 'Operação cancelada. Tente de novo.';
    default:
      final m = e.message?.trim();
      if (m != null && m.isNotEmpty) {
        return '$m (${e.code})';
      }
      return 'Erro no servidor (${e.plugin}/${e.code}).';
  }
}
