import 'entities/financeiro_contrato.dart';
import 'entities/parcela_gerada.dart';

/// Soma [months] a [date], ajustando o dia quando o mês destino tem menos dias.
DateTime addMonths(DateTime date, int months) {
  final totalMonths = date.year * 12 + (date.month - 1) + months;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(year, month, day);
}

int _reaisParaCentavos(double v) => (v * 100).round();

double _centavosParaReais(int c) => c / 100.0;

/// Gera parcelas em valor corrigido (sem juros compostos nesta etapa).
List<ParcelaGerada> gerarParcelasApartirDoContrato(FinanceiroContrato c) {
  if (!c.podeSalvarEGerarParcelas) {
    throw ArgumentError('Contrato inválido para geração');
  }
  final promoMensalidade = c.valorComDescontoPontualidade;
  final integralMensalidade = c.valorMensalidade;
  if (promoMensalidade <= 0 && integralMensalidade <= 0) {
    return [];
  }
  final n = c.duracaoMeses;
  final promoCent = _reaisParaCentavos(promoMensalidade);
  final integralCent = _reaisParaCentavos(integralMensalidade);
  final integralAplicado = integralCent > promoCent ? integralCent : 0;
  return List.generate(n, (i) {
    final venc = addMonths(c.dataPrimeiroVencimento, i);
    return ParcelaGerada(
      numero: i + 1,
      vencimento: venc,
      valor: _centavosParaReais(promoCent),
      valorIntegral: _centavosParaReais(integralAplicado),
      status: ParcelaGerada.statusPendente,
    );
  });
}
