import 'dart:math' as math;

import 'dias_atraso_uteis.dart';
import 'entities/parcela_gerada.dart';
import 'feriados_brasil.dart';

/// Regra de negócio: mensalidade com valor promocional e «perda promocional».
/// Dois degraus ativos quando [ParcelaGerada.valorIntegral] > [ParcelaGerada.valor].

const double epsPromocionalParcela = 0.009;

bool parcelaUsaDoisDegrausPromocionais(ParcelaGerada p) {
  return p.valorIntegral > p.valor + epsPromocionalParcela;
}

/// Data limite do promocional = vencimento; se domingo/feriado, próximo dia útil (sábado mantém).
DateTime limiteDataPromocional(
  DateTime vencimento,
  Set<DateTime> feriados,
) {
  return somenteData(vencimentoCobrancaEfetivo(vencimento, feriados));
}

/// Total pago com [dataPagamento] ≤ [limiteInclusive] (somente calendário).
double valorPagoAteLimiteInclusive(ParcelaGerada p, DateTime limiteInclusive) {
  if (p.valorPago <= epsPromocionalParcela) return 0;
  final dp = p.dataPagamento;
  if (dp == null) {
    // Legado: sem data — assume válido para o limite (comportamento anterior).
    return p.valorPago;
  }
  final d = somenteData(dp);
  if (d.isAfter(limiteInclusive)) return 0;
  return p.valorPago;
}

/// Dias entre vencimento **original** e consulta (calendário; mínimo 0).
/// Usado nos juros após perder o promocional (ex.: 15→20 = 5).
int diasAtrasoCalendarioVenctoOriginal(
  DateTime vencimentoOriginal,
  DateTime consulta,
) {
  final v0 = somenteData(vencimentoOriginal);
  final c0 = somenteData(consulta);
  return math.max(0, c0.difference(v0).inDays);
}

/// Valor devido na [referencia] (sem taxa de cartão).
double valorDevidoParcelaDoisDegraus({
  required ParcelaGerada parcela,
  required DateTime referencia,
  required double jurosDiarioContrato,
  required Set<DateTime> feriados,
}) {
  final limite = limiteDataPromocional(parcela.vencimento, feriados);
  final ref = somenteData(referencia);
  final vp = parcela.valor;
  final vi = parcela.valorIntegral;
  final pagoTotal = parcela.valorPago;
  final pagoLimite = valorPagoAteLimiteInclusive(parcela, limite);

  final perdeuPromo =
      ref.isAfter(limite) && pagoLimite < vp - epsPromocionalParcela;

  if (!perdeuPromo) {
    return math.max(0.0, vp - pagoTotal);
  }

  final dias =
      diasAtrasoCalendarioVenctoOriginal(parcela.vencimento, ref);
  final bruto = vi + dias * jurosDiarioContrato;
  return math.max(0.0, bruto - pagoTotal);
}
