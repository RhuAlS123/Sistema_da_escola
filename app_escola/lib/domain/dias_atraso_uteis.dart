import 'dart:math' as math;

import 'feriados_brasil.dart';

bool _ehDomingo(DateTime d) => d.weekday == DateTime.sunday;

/// Primeiro dia em que o vencimento “vale” para cobrança: não domingo nem feriado.
/// Se o vencimento cair em domingo ou em [feriados], avança até um dia válido
/// (sábado conta; domingo não).
DateTime vencimentoCobrancaEfetivo(
  DateTime vencimento,
  Set<DateTime> feriados,
) {
  var d = somenteData(vencimento);
  while (_ehDomingo(d) || feriados.contains(d)) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

/// Conta dias de atraso **úteis** (exclui domingos e feriados; **sábado conta**).
/// Intervalo: do primeiro dia após [vencimentoCobrancaEfetivo] até [fim] (inclusive).
/// Se [fim] for antes do início do atraso, retorna 0.
int diasUteisAtraso({
  required DateTime vencimento,
  required DateTime fim,
  required Set<DateTime> feriados,
}) {
  final ve = vencimentoCobrancaEfetivo(vencimento, feriados);
  final inicio = ve.add(const Duration(days: 1));
  final f0 = somenteData(fim);
  final i0 = somenteData(inicio);
  if (f0.isBefore(i0)) return 0;

  var count = 0;
  for (var d = i0; !d.isAfter(f0); d = d.add(const Duration(days: 1))) {
    if (_ehDomingo(d)) continue;
    if (feriados.contains(d)) continue;
    count++;
  }
  return count;
}

/// Feriados necessários para comparar [a] e [b] (anos cobertos) + [extras].
Set<DateTime> feriadosParaCalculo({
  required DateTime a,
  required DateTime b,
  Set<DateTime>? feriadosExtras,
}) {
  final y0 = math.min(a.year, b.year);
  final y1 = math.max(a.year, b.year);
  final base = feriadosFixosBrasilParaAnos(y0, y1);
  if (feriadosExtras == null || feriadosExtras.isEmpty) return base;
  return {...base, ...feriadosExtras.map(somenteData)};
}
