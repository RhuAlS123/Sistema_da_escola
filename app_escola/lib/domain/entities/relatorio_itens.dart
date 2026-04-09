/// Linha do relatório "Alunos em débito" (PASSOS §5.4).
class RelatorioDebitoItem {
  const RelatorioDebitoItem({
    required this.alunoId,
    required this.nomeAluno,
    required this.nomeResponsavel,
    required this.telefone,
    required this.parcelasEmAtraso,
    required this.diasAtrasoMax,
    required this.valorTotalRestante,
  });

  final String alunoId;
  final String nomeAluno;
  final String nomeResponsavel;
  final String telefone;
  final int parcelasEmAtraso;
  final int diasAtrasoMax;
  final double valorTotalRestante;
}

/// Linha do relatório "Aniversariantes do mês".
class RelatorioAniversarianteItem {
  const RelatorioAniversarianteItem({
    required this.nomeAluno,
    required this.dataNascimento,
    required this.turmasLabel,
  });

  final String nomeAluno;
  final DateTime dataNascimento;

  /// Ex.: "Tecnologia, Inglês" ou "—"
  final String turmasLabel;
}

/// Pagamentos registrados no mês (qualquer situação de pontualidade).
class RelatorioPaganteMesItem {
  const RelatorioPaganteMesItem({
    required this.alunoId,
    required this.nomeAluno,
    required this.nomeResponsavel,
    required this.quantidadePagamentos,
    required this.valorTotalPago,
  });

  final String alunoId;
  final String nomeAluno;
  final String nomeResponsavel;
  final int quantidadePagamentos;
  final double valorTotalPago;
}

/// Pagamentos **sem atraso** no mês (data pagamento ≤ vencimento) e sem parcela atrasada hoje.
class RelatorioEmDiaMesItem {
  const RelatorioEmDiaMesItem({
    required this.alunoId,
    required this.nomeAluno,
    required this.nomeResponsavel,
    required this.quantidadePagamentosEmDia,
    required this.valorTotalPago,
  });

  final String alunoId;
  final String nomeAluno;
  final String nomeResponsavel;
  final int quantidadePagamentosEmDia;
  final double valorTotalPago;
}
