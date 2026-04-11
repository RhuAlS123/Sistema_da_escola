import 'dias_atraso_uteis.dart';
import 'entities/parcela_gerada.dart';
import 'feriados_brasil.dart';
import 'parcela_status_visual.dart';

/// Pagamento considerado "em dia": há valor pago e data ≤ vencimento **efetivo**
/// (domingo/feriado no vencimento → próximo dia válido — Fase 4).
bool pagamentoParcelaSemAtraso(
  ParcelaGerada p, {
  Set<DateTime>? feriadosExtras,
}) {
  if (p.dataPagamento == null || p.valorPago <= 0) return false;
  final feriados = feriadosParaCalculo(
    a: p.vencimento,
    b: p.dataPagamento!,
    feriadosExtras: feriadosExtras,
  );
  final limite = somenteData(
    vencimentoCobrancaEfetivo(p.vencimento, feriados),
  );
  final dp = somenteData(p.dataPagamento!);
  return !dp.isAfter(limite);
}

bool _mesRef(DateTime d, int mes, int ano) =>
    d.month == mes && d.year == ano;

/// Parcela com registro de pagamento no mês/ano informados.
bool parcelaComPagamentoNoMes(ParcelaGerada p, int mes, int ano) {
  if (p.dataPagamento == null || p.valorPago <= 0) return false;
  return _mesRef(p.dataPagamento!, mes, ano);
}

bool possuiParcelaAtrasadaHoje(
  List<ParcelaGerada> parcelas,
  DateTime agora, {
  required double jurosDiarioContrato,
  Set<DateTime>? feriadosExtras,
}) {
  for (final p in parcelas) {
    if (resolverParcelaStatusVisual(
          p,
          agora,
          jurosDiarioContrato: jurosDiarioContrato,
          feriadosExtras: feriadosExtras,
        ) ==
        ParcelaStatusVisual.atrasado) {
      return true;
    }
  }
  return false;
}
