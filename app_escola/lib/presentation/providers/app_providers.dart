import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data.dart';
import '../../domain/domain.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);

final firebaseFirestoreProvider =
    Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider)),
);

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(ref.watch(firebaseFirestoreProvider)),
);

final alunoRepositoryProvider = Provider<AlunoRepository>(
  (ref) => AlunoRepository(ref.watch(firebaseFirestoreProvider)),
);

/// Índice da guia principal (0 = Cadastro geral …).
final mainTabIndexProvider = StateProvider<int>((ref) => 0);

/// Aluno em edição / recém-salvo (para a próxima guia — financeiro).
final alunoSelecionadoIdProvider = StateProvider<String?>((ref) => null);

/// Lista ordenada para Localizar aluno.
final alunosResumoProvider = StreamProvider<List<AlunoResumo>>(
  (ref) => ref.watch(alunoRepositoryProvider).watchResumosOrdenados(),
);

/// Estado de sessão Firebase Auth.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Perfil em `usuarios/{uid}`; `null` se não existir documento ou dados inválidos.
final userProfileProvider = StreamProvider<AppUserProfile?>((ref) {
  final session = ref.watch(authStateProvider);
  return session.maybeWhen(
    data: (user) {
      if (user == null) return Stream<AppUserProfile?>.value(null);
      return ref.watch(userProfileRepositoryProvider).watchProfile(user.uid);
    },
    orElse: () => Stream<AppUserProfile?>.value(null),
  );
});
