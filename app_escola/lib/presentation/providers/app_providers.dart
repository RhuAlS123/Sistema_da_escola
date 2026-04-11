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

/// Parcelas na subcoleção `alunos/{id}/parcelas` (PASSOS §5.3 — tempo real).
final parcelasDoAlunoProvider =
    StreamProvider.autoDispose.family<List<ParcelaGerada>, String>(
  (ref, alunoId) =>
      ref.watch(alunoRepositoryProvider).watchParcelasGeradas(alunoId),
);

/// Contrato financeiro do aluno (juros diário, etc. — Fase 4).
final financeiroContratoDoAlunoProvider =
    FutureProvider.autoDispose.family<FinanceiroContrato?, String>(
  (ref, alunoId) =>
      ref.watch(alunoRepositoryProvider).obterFinanceiro(alunoId),
);

/// Mês/ano de competência para relatórios **Pagantes** e **Em dia** (§5.4).
final relatorioMesReferenciaProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, 1);
});

/// Feriados nacionais (Brasil API), como no ICPROV6 — somados aos fixos no domínio.
final feriadosBrasilApiProvider = FutureProvider<Set<DateTime>>((ref) async {
  final repo = BrasilApiFeriadosRepository();
  final y = DateTime.now().year;
  return repo.feriadosParaAnos(y - 1, y + 1);
});

final relatorioDebitoProvider = FutureProvider.autoDispose((ref) async {
  final api = ref.watch(feriadosBrasilApiProvider).valueOrNull ?? {};
  return ref.watch(alunoRepositoryProvider).listarAlunosEmDebito(
        feriadosExtras: api,
      );
});

/// Aniversariantes do **mês civil atual** (documento de passos).
final relatorioAniversariantesProvider = FutureProvider.autoDispose((ref) {
  final n = DateTime.now();
  return ref.watch(alunoRepositoryProvider).listarAniversariantesDoMes(n.month);
});

final relatorioPagantesMesProvider = FutureProvider.autoDispose((ref) {
  final d = ref.watch(relatorioMesReferenciaProvider);
  return ref
      .watch(alunoRepositoryProvider)
      .listarAlunosPagantesNoMes(d.month, d.year);
});

final relatorioEmDiaMesProvider = FutureProvider.autoDispose((ref) async {
  final d = ref.watch(relatorioMesReferenciaProvider);
  final api = ref.watch(feriadosBrasilApiProvider).valueOrNull ?? {};
  return ref.watch(alunoRepositoryProvider).listarAlunosEmDiaNoMes(
        d.month,
        d.year,
        feriadosExtras: api,
      );
});

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
