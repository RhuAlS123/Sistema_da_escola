import 'dias_atraso_uteis.dart';
import 'entities/parcela_gerada.dart';
import 'feriados_brasil.dart';
import 'valor_parcela_juros.dart';

/// Cores da UI (PASSOS §5.3): pago / aberto / atrasado.
enum ParcelaStatusVisual {
  pago,
  aberto,
  atrasado,
}

/// [agora] normalmente `DateTime.now()` (somente data importa para comparação).
/// Limite «em dia» = vencimento efetivo (domingo/feriado → próximo dia útil; sábado mantém).
ParcelaStatusVisual resolverParcelaStatusVisual(
  ParcelaGerada p,
  DateTime agora, {
  required double jurosDiarioContrato,
  Set<DateTime>? feriadosExtras,
}) {
  const eps = 0.009;
  final rest = restanteParcelaComJuros(
    parcela: p,
    valorPago: p.valorPago,
    referencia: somenteData(agora),
    jurosDiarioContrato: jurosDiarioContrato,
    feriadosExtras: feriadosExtras,
  );
  final quitado =
      rest <= eps || p.status == ParcelaGerada.statusPago;
  if (quitado) return ParcelaStatusVisual.pago;

  final feriados = feriadosParaCalculo(
    a: p.vencimento,
    b: agora,
    feriadosExtras: feriadosExtras,
  );
  final limite = somenteData(
    vencimentoCobrancaEfetivo(p.vencimento, feriados),
  );
  final d0 = somenteData(agora);
  if (d0.isAfter(limite)) return ParcelaStatusVisual.atrasado;
  return ParcelaStatusVisual.aberto;
}

/// Atualiza o campo persistido `status` conforme valores pagos (§5.3).
String inferirStatusPersistido(
  ParcelaGerada p, {
  required double jurosDiarioContrato,
  Set<DateTime>? feriadosExtras,
}) {
  const eps = 0.009;
  final rest = restanteParcelaComJuros(
    parcela: p,
    valorPago: p.valorPago,
    referencia: somenteData(DateTime.now()),
    jurosDiarioContrato: jurosDiarioContrato,
    feriadosExtras: feriadosExtras,
  );
  if (rest <= eps) return ParcelaGerada.statusPago;
  if (p.valorPago > eps) return ParcelaGerada.statusParcial;
  return ParcelaGerada.statusPendente;
}
