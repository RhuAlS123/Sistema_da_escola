/// Regras de cartão de crédito do protótipo ICPROV6: taxa fixa **R\$ 5** por parcela
/// do cartão (`installments * 5` no React).
bool formaPagamentoCartaoCredito(String forma) {
  final s = forma.toLowerCase().trim();
  return s.contains('crédito') || s.contains('credito');
}

/// Taxa total em reais (mínimo 1 parcela × R\$ 5).
double taxaCartaoCreditoIcproReais(int? parcelasNoCartao) {
  final n = parcelasNoCartao ?? 1;
  return (n < 1 ? 1 : n) * 5.0;
}
