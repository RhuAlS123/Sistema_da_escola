import 'dias_atraso_uteis.dart';
import 'entities/parcela_gerada.dart';
import 'feriados_brasil.dart';

/// Cores da UI (PASSOS §5.3): pago / aberto / atrasado.
enum ParcelaStatusVisual {
  pago,
  aberto,
  atrasado,
}

/// [agora] normalmente `DateTime.now()` (somente data importa para comparação).
/// Usa vencimento **efetivo** (domingo/feriado → próximo dia válido — Fase 4).
ParcelaStatusVisual resolverParcelaStatusVisual(
  ParcelaGerada p,
  DateTime agora, {
  Set<DateTime>? feriadosExtras,
}) {
  const eps = 0.009;
  final alvo = p.valor - p.perdaPromocional;
  final quitado = p.valorPago + eps >= alvo ||
      p.status == ParcelaGerada.statusPago;
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
String inferirStatusPersistido(ParcelaGerada p) {
  const eps = 0.009;
  final alvo = p.valor - p.perdaPromocional;
  if (p.valorPago + eps >= alvo) return ParcelaGerada.statusPago;
  if (p.valorPago > eps) return ParcelaGerada.statusParcial;
  return ParcelaGerada.statusPendente;
}
