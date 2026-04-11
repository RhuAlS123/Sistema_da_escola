import '../cartao_icpro.dart';

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
    this.cartaoTaxaFixaReais = 0,
    this.atendente = '',
    this.perdaPromocional = 0,
    this.valorIntegral = 0,
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

  /// Taxa fixa total (ICPRO: R\$ 5 × parcelas no cartão), somada ao valor devido.
  final double cartaoTaxaFixaReais;

  final String atendente;

  /// Desconto promocional (Fase 4 — juros/perda; por ora 0).
  final double perdaPromocional;

  /// Valor cheio após perder o promocional (0 = contrato sem dois degraus).
  final double valorIntegral;

  static const statusPendente = 'pendente';
  static const statusParcial = 'parcial';
  static const statusPago = 'pago';

  /// Aproximação legado; na tela use o cálculo com juros do domínio.
  double get restante {
    final taxa =
        formaPagamentoCartaoCredito(formaPagamento) ? cartaoTaxaFixaReais : 0.0;
    return (valor + taxa - valorPago - perdaPromocional)
        .clamp(0.0, double.infinity);
  }

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
    double? cartaoTaxaFixaReais,
    String? atendente,
    double? perdaPromocional,
    double? valorIntegral,
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
      cartaoTaxaFixaReais: cartaoTaxaFixaReais ?? this.cartaoTaxaFixaReais,
      atendente: atendente ?? this.atendente,
      perdaPromocional: perdaPromocional ?? this.perdaPromocional,
      valorIntegral: valorIntegral ?? this.valorIntegral,
    );
  }
}
