import 'calculo_parcela_promocional.dart';
import 'cartao_icpro.dart';
import 'dias_atraso_uteis.dart';
import 'entities/parcela_gerada.dart';

/// Valor da parcela com multa/juros por **dia útil** de atraso (PASSOS Fase 4).
///
/// `mensalidade + (dias úteis de atraso × juros diário) − perda promocional`
double valorParcelaComJuros({
  required double mensalidade,
  required int diasUteisAtraso,
  required double jurosPorDiaUtil,
  required double perdaPromocional,
}) {
  final v =
      mensalidade + diasUteisAtraso * jurosPorDiaUtil - perdaPromocional;
  if (v.isNaN || v.isInfinite) return 0;
  return v < 0 ? 0 : v;
}

/// Valor devido na [referencia] (juros acumulados por dias úteis até essa data).
double valorDevidoParcelaNaData({
  required ParcelaGerada parcela,
  required DateTime referencia,
  required double jurosDiarioContrato,
  Set<DateTime>? feriadosExtras,
}) {
  final feriados = feriadosParaCalculo(
    a: parcela.vencimento,
    b: referencia,
    feriadosExtras: feriadosExtras,
  );
  if (parcelaUsaDoisDegrausPromocionais(parcela)) {
    return valorDevidoParcelaDoisDegraus(
      parcela: parcela,
      referencia: referencia,
      jurosDiarioContrato: jurosDiarioContrato,
      feriados: feriados,
    );
  }
  final dias = diasUteisAtraso(
    vencimento: parcela.vencimento,
    fim: referencia,
    feriados: feriados,
  );
  return valorParcelaComJuros(
    mensalidade: parcela.valor,
    diasUteisAtraso: dias,
    jurosPorDiaUtil: jurosDiarioContrato,
    perdaPromocional: parcela.perdaPromocional,
  );
}

/// Restante após [valorPago], usando valor devido com juros até [referencia].
double restanteParcelaComJuros({
  required ParcelaGerada parcela,
  required double valorPago,
  required DateTime referencia,
  required double jurosDiarioContrato,
  Set<DateTime>? feriadosExtras,
}) {
  final devido = valorDevidoParcelaNaData(
    parcela: parcela,
    referencia: referencia,
    jurosDiarioContrato: jurosDiarioContrato,
    feriadosExtras: feriadosExtras,
  );
  final taxaCartao = formaPagamentoCartaoCredito(parcela.formaPagamento)
      ? parcela.cartaoTaxaFixaReais
      : 0.0;
  return (devido + taxaCartao - valorPago).clamp(0.0, double.infinity);
}
