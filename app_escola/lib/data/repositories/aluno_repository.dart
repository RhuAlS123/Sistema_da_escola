import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/domain.dart';

/// Coleção `alunos` — documento com mapa `dados_pessoais` e metadados de data.
class AlunoRepository {
  AlunoRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('alunos');

  /// Lista todos os alunos em tempo real, ordenados pelo nome do aluno **no cliente**.
  /// Evita `orderBy` no Firestore (índice composto + mesmas regras de `list` na coleção).
  Stream<List<AlunoResumo>> watchResumosOrdenados() {
    return _col.snapshots().map((snap) {
      final list = snap.docs.map((d) {
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
      list.sort(
        (a, b) => a.nomeAluno.toLowerCase().compareTo(b.nomeAluno.toLowerCase()),
      );
      return list;
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

  /// Apaga `alunos/{id}` e todos os documentos em `parcelas` (regras: só **admin**).
  Future<void> excluirAluno(String alunoId) async {
    final docRef = _col.doc(alunoId);
    final parentSnap = await docRef.get();
    if (!parentSnap.exists) {
      throw StateError('Aluno não encontrado.');
    }
    final sub = await docRef.collection('parcelas').get();
    var batch = _db.batch();
    var ops = 0;
    Future<void> commitBatch() async {
      await batch.commit();
      batch = _db.batch();
      ops = 0;
    }

    for (final d in sub.docs) {
      batch.delete(d.reference);
      ops++;
      if (ops >= 450) await commitBatch();
    }
    batch.delete(docRef);
    ops++;
    await commitBatch();
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

  Future<FinanceiroContrato?> obterFinanceiro(String alunoId) async {
    final doc = await _col.doc(alunoId).get();
    if (!doc.exists) return null;
    return _mapFinanceiroContrato(doc.data());
  }

  /// Tempo real — alinhado ao PASSOS §5.3.
  Stream<List<ParcelaGerada>> watchParcelasGeradas(String alunoId) {
    return _col
        .doc(alunoId)
        .collection('parcelas')
        .orderBy('numero')
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => _mapParcela(d.data()))
          .whereType<ParcelaGerada>()
          .toList();
    });
  }

  Future<List<ParcelaGerada>> obterParcelasGeradas(String alunoId) async {
    final sub = await _col
        .doc(alunoId)
        .collection('parcelas')
        .orderBy('numero')
        .get();
    if (sub.docs.isNotEmpty) {
      return sub.docs
          .map((d) => _mapParcela(d.data()))
          .whereType<ParcelaGerada>()
          .toList();
    }
    final doc = await _col.doc(alunoId).get();
    if (!doc.exists) return [];
    final raw = doc.data()?['parcelas_geradas'];
    if (raw is! List) return [];
    final out = <ParcelaGerada>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        final p = _mapParcela(item);
        if (p != null) out.add(p);
      } else if (item is Map) {
        final p = _mapParcela(Map<String, dynamic>.from(item));
        if (p != null) out.add(p);
      }
    }
    return out;
  }

  /// `financeiro_contrato` + subcoleção `parcelas` (PASSOS §2).
  Future<void> salvarFinanceiroGerarParcelas({
    required String alunoId,
    required FinanceiroContrato financeiro,
  }) async {
    final parcelas = gerarParcelasApartirDoContrato(financeiro);
    final docRef = _col.doc(alunoId);
    await docRef.update({
      'financeiro_contrato': _financeiroContratoToMap(financeiro),
      'financeiro': FieldValue.delete(),
      'parcelas_geradas': FieldValue.delete(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    await _substituirParcelasSubcolecao(alunoId, parcelas);
  }

  Future<void> _substituirParcelasSubcolecao(
    String alunoId,
    List<ParcelaGerada> parcelas,
  ) async {
    final col = _col.doc(alunoId).collection('parcelas');
    final existentes = await col.get();
    var batch = _db.batch();
    var ops = 0;

    Future<void> flush() async {
      if (ops > 0) {
        await batch.commit();
        batch = _db.batch();
        ops = 0;
      }
    }

    for (final d in existentes.docs) {
      batch.delete(d.reference);
      ops++;
      if (ops >= 450) await flush();
    }
    await flush();

    for (final p in parcelas) {
      batch.set(col.doc('${p.numero}'), _parcelaToMap(p));
      ops++;
      if (ops >= 450) await flush();
    }
    await flush();
  }

  Future<void> definirBloqueioFinanceiro({
    required String alunoId,
    required bool locked,
  }) async {
    final docRef = _col.doc(alunoId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw StateError('Aluno não encontrado.');
    }
    final root = snap.data()!;
    final useNovo = root['financeiro_contrato'] != null;
    final raw = useNovo
        ? root['financeiro_contrato']
        : root['financeiro'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('Cadastro financeiro ainda não existe.');
    }
    final fin = Map<String, dynamic>.from(raw);
    fin['is_locked'] = locked;
    await docRef.update(useNovo
        ? {
            'financeiro_contrato': fin,
            'atualizadoEm': FieldValue.serverTimestamp(),
          }
        : {
            'financeiro': fin,
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
  }

  Map<String, dynamic> _financeiroContratoToMap(FinanceiroContrato c) {
    return {
      'data_matricula': Timestamp.fromDate(c.dataMatricula),
      'pacote': c.pacoteLabel,
      'pacote_outros': c.pacoteOutrosDetalhe,
      'turma_tecnologia': c.turmaTecnologia,
      'turma_ingles': c.turmaIngles,
      'turma_horario_tecnologia': c.turmaHorarioTecnologia,
      'turma_horario_ingles': c.turmaHorarioIngles,
      'data_primeiro_vencimento':
          Timestamp.fromDate(c.dataPrimeiroVencimento),
      'duracao_meses': c.duracaoMeses,
      'valor_total': c.valorTotal,
      'valor_entrada': c.valorEntrada,
      'taxas': c.taxas,
      'status_contrato': c.statusContrato,
      'observacao': c.observacao,
      'is_locked': c.isLocked,
      'juros_diario': c.jurosDiario,
      'ref_valor_mensal_promo': c.refValorMensalPromo,
      'ref_valor_mensal_integral': c.refValorMensalIntegral,
    };
  }

  FinanceiroContrato? _mapFinanceiroContrato(Map<String, dynamic>? root) {
    if (root == null) return null;
    Map<String, dynamic>? f = root['financeiro_contrato'] as Map<String, dynamic>?;
    final leg = root['financeiro'];
    if (f == null && leg is Map<String, dynamic>) {
      f = _migrarFinanceiroLegacy(leg);
    }
    if (f == null) return null;
    return _contratoFromMap(f);
  }

  Map<String, dynamic> _migrarFinanceiroLegacy(Map<String, dynamic> old) {
    return {
      'data_matricula': old['data_primeira_parcela'],
      'pacote': 'Completo',
      'pacote_outros': '',
      'turma_tecnologia': false,
      'turma_ingles': false,
      'turma_horario_tecnologia': '',
      'turma_horario_ingles': '',
      'data_primeiro_vencimento': old['data_primeira_parcela'],
      'duracao_meses': old['num_parcelas'] ?? 1,
      'valor_total': old['valor_total'],
      'valor_entrada': old['valor_entrada'],
      'taxas': 0,
      'status_contrato': FinanceiroContrato.statusMensalista,
      'observacao': old['observacoes'] ?? '',
      'is_locked': old['is_locked'] == true,
    };
  }

  FinanceiroContrato _contratoFromMap(Map<String, dynamic> f) {
    DateTime? tsToDate(dynamic t) {
      if (t is Timestamp) return t.toDate();
      return null;
    }

    final hoje = DateTime.now();
    final padraoDia = DateTime(hoje.year, hoje.month, hoje.day);

    return FinanceiroContrato(
      dataMatricula: tsToDate(f['data_matricula']) ?? padraoDia,
      pacoteLabel: '${f['pacote'] ?? 'Completo'}',
      pacoteOutrosDetalhe: '${f['pacote_outros'] ?? ''}',
      turmaTecnologia: f['turma_tecnologia'] == true,
      turmaIngles: f['turma_ingles'] == true,
      turmaHorarioTecnologia: '${f['turma_horario_tecnologia'] ?? ''}',
      turmaHorarioIngles: '${f['turma_horario_ingles'] ?? ''}',
      dataPrimeiroVencimento:
          tsToDate(f['data_primeiro_vencimento']) ?? padraoDia,
      duracaoMeses: (f['duracao_meses'] as num?)?.toInt() ??
          (f['num_parcelas'] as num?)?.toInt() ??
          1,
      valorTotal: (f['valor_total'] as num?)?.toDouble() ?? 0,
      valorEntrada: (f['valor_entrada'] as num?)?.toDouble() ?? 0,
      taxas: (f['taxas'] as num?)?.toDouble() ?? 0,
      statusContrato: '${f['status_contrato'] ?? FinanceiroContrato.statusMensalista}',
      observacao: '${f['observacao'] ?? f['observacoes'] ?? ''}',
      isLocked: f['is_locked'] == true,
      jurosDiario: (f['juros_diario'] as num?)?.toDouble() ?? 0,
      refValorMensalPromo:
          (f['ref_valor_mensal_promo'] as num?)?.toDouble() ?? 0,
      refValorMensalIntegral:
          (f['ref_valor_mensal_integral'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> _parcelaToMap(ParcelaGerada p) {
    return {
      'numero': p.numero,
      'vencimento': Timestamp.fromDate(p.vencimento),
      'valor': p.valor,
      'status': p.status,
      'data_pagamento': p.dataPagamento != null
          ? Timestamp.fromDate(p.dataPagamento!)
          : null,
      'valor_pago': p.valorPago,
      'forma_pagamento': p.formaPagamento,
      'cartao_parcelas': p.cartaoParcelas,
      'cartao_taxa_pct': p.cartaoTaxaPct,
      'cartao_taxa_fixa': p.cartaoTaxaFixaReais,
      'atendente': p.atendente,
      'perda_promocional': p.perdaPromocional,
      'valor_integral': p.valorIntegral,
    };
  }

  ParcelaGerada? _mapParcela(Map<String, dynamic> m) {
    DateTime? tsToDate(dynamic t) {
      if (t is Timestamp) return t.toDate();
      return null;
    }

    final n = (m['numero'] as num?)?.toInt();
    final v = (m['valor'] as num?)?.toDouble();
    final ven = tsToDate(m['vencimento']);
    if (n == null || v == null || ven == null) return null;
    return ParcelaGerada(
      numero: n,
      vencimento: ven,
      valor: v,
      status: '${m['status'] ?? ParcelaGerada.statusPendente}',
      dataPagamento: tsToDate(m['data_pagamento']),
      valorPago: (m['valor_pago'] as num?)?.toDouble() ?? 0,
      formaPagamento: '${m['forma_pagamento'] ?? ''}',
      cartaoParcelas: (m['cartao_parcelas'] as num?)?.toInt(),
      cartaoTaxaPct: (m['cartao_taxa_pct'] as num?)?.toDouble() ?? 0,
      cartaoTaxaFixaReais: (m['cartao_taxa_fixa'] as num?)?.toDouble() ?? 0,
      atendente: '${m['atendente'] ?? ''}',
      perdaPromocional: (m['perda_promocional'] as num?)?.toDouble() ?? 0,
      valorIntegral: (m['valor_integral'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Atualiza uma parcela na subcoleção (salvar por linha — §5.3).
  Future<void> salvarParcela({
    required String alunoId,
    required ParcelaGerada parcela,
    double jurosDiarioContrato = 0,
    Set<DateTime> feriadosExtras = const {},
  }) async {
    final extras = feriadosExtras.isEmpty ? null : feriadosExtras;
    final comStatus = parcela.copyWith(
      status: inferirStatusPersistido(
        parcela,
        jurosDiarioContrato: jurosDiarioContrato,
        feriadosExtras: extras,
      ),
    );
    await _col
        .doc(alunoId)
        .collection('parcelas')
        .doc('${parcela.numero}')
        .set(_parcelaToMap(comStatus), SetOptions(merge: true));
  }

  // --- Relatórios (PASSOS §5.4)

  Future<List<RelatorioDebitoItem>> listarAlunosEmDebito({
    Set<DateTime> feriadosExtras = const {},
  }) async {
    final snap = await _col.get();
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final extras = feriadosExtras.isEmpty ? null : feriadosExtras;
    final out = <RelatorioDebitoItem>[];
    for (final d in snap.docs) {
      final dados = _mapDadosPessoais(d.data());
      if (dados == null) continue;
      final parcelas = await obterParcelasGeradas(d.id);
      final atrasadas = <ParcelaGerada>[];
      final fin = await obterFinanceiro(d.id);
      final juros = fin?.jurosDiario ?? 0;
      for (final p in parcelas) {
        if (resolverParcelaStatusVisual(
              p,
              agora,
              jurosDiarioContrato: juros,
              feriadosExtras: extras,
            ) ==
            ParcelaStatusVisual.atrasado) {
          atrasadas.add(p);
        }
      }
      if (atrasadas.isEmpty) continue;
      var maxDias = 0;
      for (final p in atrasadas) {
        final feriados = feriadosParaCalculo(
          a: p.vencimento,
          b: hoje,
          feriadosExtras: extras,
        );
        final dias = parcelaUsaDoisDegrausPromocionais(p)
            ? diasAtrasoCalendarioVenctoOriginal(p.vencimento, hoje)
            : diasUteisAtraso(
                vencimento: p.vencimento,
                fim: hoje,
                feriados: feriados,
              );
        if (dias > maxDias) maxDias = dias;
      }
      final total = atrasadas.fold<double>(0, (s, p) {
        return s +
            restanteParcelaComJuros(
              parcela: p,
              valorPago: p.valorPago,
              referencia: hoje,
              jurosDiarioContrato: juros,
              feriadosExtras: extras,
            );
      });
      out.add(
        RelatorioDebitoItem(
          alunoId: d.id,
          nomeAluno: dados.nomeAluno,
          nomeResponsavel: dados.nomeResponsavel,
          telefone: dados.telefone,
          parcelasEmAtraso: atrasadas.length,
          diasAtrasoMax: maxDias,
          valorTotalRestante: total,
        ),
      );
    }
    out.sort((a, b) => b.valorTotalRestante.compareTo(a.valorTotalRestante));
    return out;
  }

  Future<List<RelatorioAniversarianteItem>> listarAniversariantesDoMes(
    int mes,
  ) async {
    final snap = await _col.get();
    final out = <RelatorioAniversarianteItem>[];
    for (final d in snap.docs) {
      final dados = _mapDadosPessoais(d.data());
      final nasc = dados?.dataNascimentoAluno;
      if (dados == null || nasc == null) continue;
      if (nasc.month != mes) continue;
      final fin = await obterFinanceiro(d.id);
      out.add(
        RelatorioAniversarianteItem(
          nomeAluno: dados.nomeAluno,
          dataNascimento: nasc,
          turmasLabel: _turmasResumo(fin),
        ),
      );
    }
    out.sort((a, b) => a.dataNascimento.day.compareTo(b.dataNascimento.day));
    return out;
  }

  String _turmasResumo(FinanceiroContrato? f) {
    if (f == null) return '—';
    final p = <String>[];
    if (f.turmaTecnologia) {
      final h = f.turmaHorarioTecnologia.trim();
      p.add(h.isEmpty ? 'Tecnologia' : 'Tecnologia ($h)');
    }
    if (f.turmaIngles) {
      final h = f.turmaHorarioIngles.trim();
      p.add(h.isEmpty ? 'Inglês' : 'Inglês ($h)');
    }
    return p.isEmpty ? '—' : p.join(', ');
  }

  Future<List<RelatorioPaganteMesItem>> listarAlunosPagantesNoMes(
    int mes,
    int ano,
  ) async {
    final snap = await _col.get();
    final out = <RelatorioPaganteMesItem>[];
    for (final d in snap.docs) {
      final dados = _mapDadosPessoais(d.data());
      if (dados == null) continue;
      final parcelas = await obterParcelasGeradas(d.id);
      var q = 0;
      var soma = 0.0;
      for (final p in parcelas) {
        if (parcelaComPagamentoNoMes(p, mes, ano)) {
          q++;
          soma += p.valorPago;
        }
      }
      if (q == 0) continue;
      out.add(
        RelatorioPaganteMesItem(
          alunoId: d.id,
          nomeAluno: dados.nomeAluno,
          nomeResponsavel: dados.nomeResponsavel,
          quantidadePagamentos: q,
          valorTotalPago: soma,
        ),
      );
    }
    out.sort((a, b) => a.nomeAluno.compareTo(b.nomeAluno));
    return out;
  }

  Future<List<RelatorioEmDiaMesItem>> listarAlunosEmDiaNoMes(
    int mes,
    int ano, {
    Set<DateTime> feriadosExtras = const {},
  }) async {
    final snap = await _col.get();
    final agora = DateTime.now();
    final extras = feriadosExtras.isEmpty ? null : feriadosExtras;
    final out = <RelatorioEmDiaMesItem>[];
    for (final d in snap.docs) {
      final dados = _mapDadosPessoais(d.data());
      if (dados == null) continue;
      final parcelas = await obterParcelasGeradas(d.id);
      final finEmDia = await obterFinanceiro(d.id);
      final jurosEmDia = finEmDia?.jurosDiario ?? 0;
      if (possuiParcelaAtrasadaHoje(
            parcelas,
            agora,
            jurosDiarioContrato: jurosEmDia,
            feriadosExtras: extras,
          )) {
        continue;
      }
      var q = 0;
      var soma = 0.0;
      for (final p in parcelas) {
        if (!parcelaComPagamentoNoMes(p, mes, ano)) continue;
        if (!pagamentoParcelaSemAtraso(
              p,
              feriadosExtras: extras,
            )) {
          continue;
        }
        q++;
        soma += p.valorPago;
      }
      if (q == 0) continue;
      out.add(
        RelatorioEmDiaMesItem(
          alunoId: d.id,
          nomeAluno: dados.nomeAluno,
          nomeResponsavel: dados.nomeResponsavel,
          quantidadePagamentosEmDia: q,
          valorTotalPago: soma,
        ),
      );
    }
    out.sort((a, b) => a.nomeAluno.compareTo(b.nomeAluno));
    return out;
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
