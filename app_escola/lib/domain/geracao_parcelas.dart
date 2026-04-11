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

/// Fator integral ÷ promo nas referências do contrato (opcional).
double? _fatorValorIntegral(FinanceiroContrato c) {
  final a = c.refValorMensalPromo;
  final b = c.refValorMensalIntegral;
  if (a <= 0 || b <= a + 1e-6) return null;
  return b / a;
}

/// Distribui o total em centavos em [n] parcelas; o resto vai para a última.
List<int> _distribuirCentavos(int totalCentavos, int n) {
  if (n <= 0) {
    throw ArgumentError.value(n, 'n', 'n deve ser >= 1');
  }
  final base = totalCentavos ~/ n;
  final resto = totalCentavos % n;
  return List.generate(n, (i) {
    if (i < n - 1) return base;
    return base + resto;
  });
}

/// Gera parcelas em valor corrigido (sem juros compostos nesta etapa).
List<ParcelaGerada> gerarParcelasApartirDoContrato(FinanceiroContrato c) {
  if (!c.podeSalvarEGerarParcelas) {
    throw ArgumentError('Contrato inválido para geração');
  }
  if (c.saldoFinanciado <= 0) {
    return [];
  }
  final totalCentavos = _reaisParaCentavos(c.saldoFinanciado);
  final n = c.duracaoMeses;
  final valores = _distribuirCentavos(totalCentavos, n);
  final fatorIntegral = _fatorValorIntegral(c);
  return List.generate(n, (i) {
    final venc = addMonths(c.dataPrimeiroVencimento, i);
    final promoCent = valores[i];
    final integralCent = fatorIntegral == null
        ? 0
        : (promoCent * fatorIntegral).round();
    return ParcelaGerada(
      numero: i + 1,
      vencimento: venc,
      valor: _centavosParaReais(promoCent),
      valorIntegral: _centavosParaReais(integralCent),
      status: ParcelaGerada.statusPendente,
    );
  });
}
