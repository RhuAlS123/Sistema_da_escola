/// Conteúdo de `alunos/{id}.financeiro_contrato` (PASSOS §5.2).
class FinanceiroContrato {
  const FinanceiroContrato({
    required this.dataMatricula,
    required this.pacoteLabel,
    required this.pacoteOutrosDetalhe,
    required this.turmaTecnologia,
    required this.turmaIngles,
    this.turmaHorarioTecnologia = '',
    this.turmaHorarioIngles = '',
    required this.dataPrimeiroVencimento,
    required this.duracaoMeses,
    required this.valorTotal,
    required this.valorEntrada,
    required this.taxas,
    required this.statusContrato,
    required this.observacao,
    required this.isLocked,
    this.jurosDiario = 0,
    this.refValorMensalPromo = 0,
    this.refValorMensalIntegral = 0,
  });

  final DateTime dataMatricula;

  /// Rótulo do pacote (lista fixa + **Outros**).
  final String pacoteLabel;

  /// Preenchido quando [pacoteLabel] é [pacoteOutros].
  final String pacoteOutrosDetalhe;

  final bool turmaTecnologia;
  final bool turmaIngles;

  /// Turma e horário (ex.: «3ª feira 14h–16h») quando [turmaTecnologia].
  final String turmaHorarioTecnologia;

  /// Turma e horário quando [turmaIngles].
  final String turmaHorarioIngles;

  /// Primeiro vencimento; as demais parcelas seguem mensalmente (§5.2).
  final DateTime dataPrimeiroVencimento;

  /// Quantidade de parcelas = duração em meses (PASSOS).
  final int duracaoMeses;

  final double valorTotal;
  final double valorEntrada;

  /// Taxas adicionais descontadas do valor a parcelar (além da entrada).
  final double taxas;

  /// `mensalista` | `bolsista`
  final String statusContrato;

  final String observacao;
  final bool isLocked;

  /// Multa diária em R\$: com **dois degraus** (promo + integral), conta **dias corridos**
  /// após perder o promocional; caso contrário, dias **úteis** (legado).
  final double jurosDiario;

  /// Referência opcional: valor mensal promocional (ex. 100). Usado só para calcular o fator
  /// integral/promo nas parcelas geradas, junto com [refValorMensalIntegral].
  final double refValorMensalPromo;

  /// Referência opcional: mensalidade cheia após perder promo (ex. 200).
  final double refValorMensalIntegral;

  static const pacoteOutros = 'Outros';
  static const statusMensalista = 'mensalista';
  static const statusBolsista = 'bolsista';

  static const pacotesPredefinidos = <String>[
    'Completo',
    'Parcial',
    'Intensivo',
    pacoteOutros,
  ];

  /// Valor financiado em parcelas: total − entrada − taxas.
  double get saldoFinanciado => valorTotal - valorEntrada - taxas;

  bool get podeSalvarContratoBasico =>
      duracaoMeses >= 1 &&
      duracaoMeses <= 120 &&
      valorTotal >= 0 &&
      valorEntrada >= 0 &&
      valorEntrada <= valorTotal &&
      taxas >= 0 &&
      valorTotal >= valorEntrada + taxas &&
      jurosDiario >= 0 &&
      (statusContrato == statusMensalista || statusContrato == statusBolsista);

  bool get pacoteOutrosValido =>
      pacoteLabel != pacoteOutros || pacoteOutrosDetalhe.trim().isNotEmpty;

  bool get turmasHorariosValidos =>
      (!turmaTecnologia || turmaHorarioTecnologia.trim().isNotEmpty) &&
      (!turmaIngles || turmaHorarioIngles.trim().isNotEmpty);

  /// Geração automática: quantidade = [duracaoMeses] (documento de passos).
  bool get podeSalvarEGerarParcelas {
    if (!podeSalvarContratoBasico || !pacoteOutrosValido || !turmasHorariosValidos) {
      return false;
    }
    if (saldoFinanciado > 0) {
      return duracaoMeses >= 1;
    }
    return true;
  }
}
