/// Documento em `alunos/{id}/parcelas/{numero}` (PASSOS §5.3).
class ParcelaGerada {
  const ParcelaGerada({
    required this.numero,
    required this.vencimento,
    required this.valor,
    this.status = statusPendente,
    this.dataPagamento,
    this.valorPago = 0,
    this.formaPagamento = '',
    this.cartaoParcelas,
    this.cartaoTaxaPct = 0,
    this.atendente = '',
    this.perdaPromocional = 0,
  });

  final int numero;
  final DateTime vencimento;

  /// Valor previsto da parcela (mensalidade).
  final double valor;

  /// `pendente` | `parcial` | `pago`
  final String status;

  final DateTime? dataPagamento;
  final double valorPago;

  /// Ex.: PIX, dinheiro, cartão crédito…
  final String formaPagamento;

  /// Parcelamento no cartão (quantidade de vezes).
  final int? cartaoParcelas;

  /// Taxa % do cartão (se aplicável).
  final double cartaoTaxaPct;

  final String atendente;

  /// Desconto promocional (Fase 4 — juros/perda; por ora 0).
  final double perdaPromocional;

  static const statusPendente = 'pendente';
  static const statusParcial = 'parcial';
  static const statusPago = 'pago';

  double get restante =>
      (valor - valorPago - perdaPromocional).clamp(0.0, double.infinity);

  ParcelaGerada copyWith({
    int? numero,
    DateTime? vencimento,
    double? valor,
    String? status,
    DateTime? dataPagamento,
    double? valorPago,
    String? formaPagamento,
    int? cartaoParcelas,
    double? cartaoTaxaPct,
    String? atendente,
    double? perdaPromocional,
  }) {
    return ParcelaGerada(
      numero: numero ?? this.numero,
      vencimento: vencimento ?? this.vencimento,
      valor: valor ?? this.valor,
      status: status ?? this.status,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      valorPago: valorPago ?? this.valorPago,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      cartaoParcelas: cartaoParcelas ?? this.cartaoParcelas,
      cartaoTaxaPct: cartaoTaxaPct ?? this.cartaoTaxaPct,
      atendente: atendente ?? this.atendente,
      perdaPromocional: perdaPromocional ?? this.perdaPromocional,
    );
  }
}
