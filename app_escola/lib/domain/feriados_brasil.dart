import 'dart:math' as math;

/// Somente calendário (hora 0).
DateTime somenteData(DateTime d) => DateTime(d.year, d.month, d.day);

/// Feriados **nacionais fixos** (Brasil) para o ano — lista extensível (Fase 4).
/// Não inclui Carnaval/Páscoa (móveis); use [feriadosExtras] no cálculo.
Set<DateTime> feriadosNacionaisFixosBrasil(int ano) {
  DateTime d(int mes, int dia) => DateTime(ano, mes, dia);
  return {
    d(1, 1), // Confraternização universal
    d(4, 21), // Tiradentes
    d(5, 1), // Trabalho
    d(9, 7), // Independência
    d(10, 12), // N.S. Aparecida
    d(11, 2), // Finados
    d(11, 15), // Proclamação da República
    d(12, 25), // Natal
  };
}

/// União de feriados fixos para todos os anos no intervalo **[anoInicio, anoFim]**.
Set<DateTime> feriadosFixosBrasilParaAnos(int anoInicio, int anoFim) {
  final a0 = math.min(anoInicio, anoFim);
  final a1 = math.max(anoInicio, anoFim);
  final out = <DateTime>{};
  for (var y = a0; y <= a1; y++) {
    out.addAll(feriadosNacionaisFixosBrasil(y));
  }
  return out;
}
