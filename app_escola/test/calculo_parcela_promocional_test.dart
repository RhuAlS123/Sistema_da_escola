import 'package:app_escola/domain/calculo_parcela_promocional.dart';
import 'package:app_escola/domain/entities/parcela_gerada.dart';
import 'package:flutter_test/flutter_test.dart';

ParcelaGerada _p({
  required DateTime venc,
  double valor = 100,
  double integral = 200,
  double pago = 0,
  DateTime? dataPago,
}) {
  return ParcelaGerada(
    numero: 1,
    vencimento: venc,
    valor: valor,
    valorIntegral: integral,
    valorPago: pago,
    dataPagamento: dataPago,
  );
}

void main() {
  const juros = 0.10;
  final feriadosVazio = <DateTime>{};

  test('vencimento em sábado: limite continua no mesmo sábado', () {
    final venc = DateTime(2026, 1, 17);
    expect(venc.weekday, DateTime.saturday);
    final lim = limiteDataPromocional(venc, feriadosVazio);
    expect(lim, DateTime(2026, 1, 17));
  });

  test('ex1: consulta no sábado do vencimento — deve promo 100', () {
    final venc = DateTime(2026, 1, 17);
    final d = valorDevidoParcelaDoisDegraus(
      parcela: _p(venc: venc),
      referencia: DateTime(2026, 1, 17),
      jurosDiarioContrato: juros,
      feriados: feriadosVazio,
    );
    expect(d, closeTo(100, 0.001));
  });

  test('ex2: consulta segunda após sábado — 2 dias corridos, integral + juros', () {
    final venc = DateTime(2026, 1, 17);
    final d = valorDevidoParcelaDoisDegraus(
      parcela: _p(venc: venc),
      referencia: DateTime(2026, 1, 19),
      jurosDiarioContrato: juros,
      feriados: feriadosVazio,
    );
    expect(d, closeTo(200.20, 0.001));
  });

  test('ex3: vencimento domingo 18/01 — limite segunda 19; consulta 19 em dia 100', () {
    final venc = DateTime(2026, 1, 18);
    expect(venc.weekday, DateTime.sunday);
    final lim = limiteDataPromocional(venc, feriadosVazio);
    expect(lim, DateTime(2026, 1, 19));
    final d = valorDevidoParcelaDoisDegraus(
      parcela: _p(venc: venc),
      referencia: DateTime(2026, 1, 19),
      jurosDiarioContrato: juros,
      feriados: feriadosVazio,
    );
    expect(d, closeTo(100, 0.001));
  });

  test('ex4: parcial 50 no vencimento; 5 dias corridos de juros até consulta', () {
    final venc = DateTime(2026, 1, 17);
    final d = valorDevidoParcelaDoisDegraus(
      parcela: _p(
        venc: venc,
        pago: 50,
        dataPago: DateTime(2026, 1, 17),
      ),
      referencia: DateTime(2026, 1, 22),
      jurosDiarioContrato: juros,
      feriados: feriadosVazio,
    );
    expect(d, closeTo(150.50, 0.001));
  });
}
