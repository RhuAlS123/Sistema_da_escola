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
    required this.valorMensalidade,
    required this.taxaMatricula,
    required this.valorPerdaPromocional,
    required this.statusContrato,
    required this.observacao,
    required this.isLocked,
    this.jurosDiario = 0,
    this.taxaSegundaViaContrato = 0,
    this.taxaReteste = 0,
    this.multaRescisoria = 0,
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

  /// Valor cheio da mensalidade.
  final double valorMensalidade;

  /// Valor pago no ato da matrícula.
  final double taxaMatricula;

  /// Desconto perdido quando o pagamento é após vencimento.
  final double valorPerdaPromocional;

  /// `mensalista` | `bolsista`
  final String statusContrato;

  final String observacao;
  final bool isLocked;

  /// Multa diária em R\$: com **dois degraus** (promo + integral), conta **dias corridos**
  /// após perder o promocional; caso contrário, dias **úteis** (legado).
  final double jurosDiario;

  /// Taxa fixa manual para emissão de 2ª via de contrato.
  final double taxaSegundaViaContrato;

  /// Taxa fixa manual para reteste.
  final double taxaReteste;

  /// Valor manual para multa rescisória.
  final double multaRescisoria;

  static const pacoteOutros = 'Outros';
  static const statusMensalista = 'mensalista';
  static const statusBolsista = 'bolsista';

  static const pacotesPredefinidos = <String>[
    'Completo',
    'Parcial',
    'Intensivo',
    pacoteOutros,
  ];

  /// Valor com desconto de pontualidade.
  double get valorComDescontoPontualidade =>
      (valorMensalidade - valorPerdaPromocional).clamp(0.0, double.infinity);

  /// Resumo solicitado pela operação: mensalidade − taxa de matrícula.
  double get saldoFinanciado => valorMensalidade - taxaMatricula;

  bool get podeSalvarContratoBasico =>
      duracaoMeses >= 1 &&
      duracaoMeses <= 120 &&
      valorMensalidade >= 0 &&
      taxaMatricula >= 0 &&
      taxaMatricula <= valorMensalidade &&
      valorPerdaPromocional >= 0 &&
      valorPerdaPromocional <= valorMensalidade &&
      jurosDiario >= 0 &&
      taxaSegundaViaContrato >= 0 &&
      taxaReteste >= 0 &&
      multaRescisoria >= 0 &&
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
    if (valorComDescontoPontualidade > 0 || valorMensalidade > 0) {
      return duracaoMeses >= 1;
    }
    return true;
  }
}
