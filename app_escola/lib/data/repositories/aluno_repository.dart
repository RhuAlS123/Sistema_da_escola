import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/domain.dart';

/// Coleção `alunos` — documento com mapa `dados_pessoais` e metadados de data.
class AlunoRepository {
  AlunoRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('alunos');

  Stream<List<AlunoResumo>> watchResumosOrdenados() {
    return _col
        .orderBy('dados_pessoais.nome_aluno')
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final dp = d.data()['dados_pessoais'];
        if (dp is! Map<String, dynamic>) {
          return AlunoResumo(
            id: d.id,
            nomeAluno: '',
            nomeResponsavel: '',
          );
        }
        return AlunoResumo(
          id: d.id,
          nomeAluno: '${dp['nome_aluno'] ?? ''}',
          nomeResponsavel: '${dp['nome_responsavel'] ?? ''}',
        );
      }).toList();
    });
  }

  Future<DadosPessoaisCadastro?> obterDadosPessoais(String alunoId) async {
    final doc = await _col.doc(alunoId).get();
    if (!doc.exists) return null;
    return _mapDadosPessoais(doc.data());
  }

  Future<String> criar(DadosPessoaisCadastro dados) async {
    final ref = await _col.add({
      'dados_pessoais': _dadosToMap(dados),
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> atualizar(String alunoId, DadosPessoaisCadastro dados) {
    return _col.doc(alunoId).update({
      'dados_pessoais': _dadosToMap(dados),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Map<String, dynamic> _dadosToMap(DadosPessoaisCadastro d) {
    return {
      'nome_responsavel': d.nomeResponsavel,
      'telefone': d.telefone,
      'cpf': d.cpf,
      'rg': d.rg,
      'data_nascimento_responsavel': d.dataNascimentoResponsavel != null
          ? Timestamp.fromDate(d.dataNascimentoResponsavel!)
          : null,
      'endereco': d.endereco,
      'cidade': d.cidade,
      'parentesco': d.parentesco,
      'nome_aluno': d.nomeAluno,
      'data_nascimento_aluno': d.dataNascimentoAluno != null
          ? Timestamp.fromDate(d.dataNascimentoAluno!)
          : null,
    };
  }

  DadosPessoaisCadastro? _mapDadosPessoais(Map<String, dynamic>? root) {
    if (root == null) return null;
    final dp = root['dados_pessoais'];
    if (dp is! Map<String, dynamic>) return null;
    DateTime? tsToDate(dynamic t) {
      if (t is Timestamp) return t.toDate();
      return null;
    }

    return DadosPessoaisCadastro(
      nomeResponsavel: '${dp['nome_responsavel'] ?? ''}',
      telefone: '${dp['telefone'] ?? ''}',
      cpf: '${dp['cpf'] ?? ''}',
      rg: '${dp['rg'] ?? ''}',
      dataNascimentoResponsavel: tsToDate(dp['data_nascimento_responsavel']),
      endereco: '${dp['endereco'] ?? ''}',
      cidade: '${dp['cidade'] ?? ''}',
      parentesco: '${dp['parentesco'] ?? ''}',
      nomeAluno: '${dp['nome_aluno'] ?? ''}',
      dataNascimentoAluno: tsToDate(dp['data_nascimento_aluno']),
    );
  }
}
