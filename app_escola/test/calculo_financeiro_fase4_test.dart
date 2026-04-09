import 'package:app_escola/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('vencimentoCobrancaEfetivo', () {
    test('domingo vira próximo dia que não é domingo nem feriado', () {
      final v = DateTime(2026, 1, 4); // domingo
      final feriados = feriadosFixosBrasilParaAnos(2026, 2026);
      final e = vencimentoCobrancaEfetivo(v, feriados);
      expect(e, DateTime(2026, 1, 5)); // segunda
    });

    test('sábado permanece sábado se não for feriado', () {
      final v = DateTime(2026, 1, 10); // sábado
      final feriados = feriadosFixosBrasilParaAnos(2026, 2026);
      final e = vencimentoCobrancaEfetivo(v, feriados);
      expect(e.weekday, DateTime.saturday);
      expect(e.day, 10);
    });
  });

  group('diasUteisAtraso', () {
    test('sem atraso quando fim é no último dia em dia', () {
      final v = DateTime(2026, 1, 5); // segunda
      final feriados = feriadosFixosBrasilParaAnos(2026, 2026);
      final ve = vencimentoCobrancaEfetivo(v, feriados);
      expect(
        diasUteisAtraso(
          vencimento: v,
          fim: ve,
          feriados: feriados,
        ),
        0,
      );
    });

    test('conta sábado e exclui domingo no meio do atraso', () {
      final v = DateTime(2026, 1, 9); // sexta — efetivo sexta
      final feriados = feriadosFixosBrasilParaAnos(2026, 2026);
      final fim = DateTime(2026, 1, 12); // segunda
      final d = diasUteisAtraso(
        vencimento: v,
        fim: fim,
        feriados: feriados,
      );
      // atraso: 10 sáb, 11 domingo (fora), 12 seg → 2 dias úteis
      expect(d, 2);
    });
  });

  group('valorParcelaComJuros', () {
    test('fórmula mensalidade + dias*juros - perda', () {
      expect(
        valorParcelaComJuros(
          mensalidade: 100,
          diasUteisAtraso: 3,
          jurosPorDiaUtil: 2,
          perdaPromocional: 5,
        ),
        101,
      );
    });

    test('não negativo', () {
      expect(
        valorParcelaComJuros(
          mensalidade: 10,
          diasUteisAtraso: 0,
          jurosPorDiaUtil: 0,
          perdaPromocional: 50,
        ),
        0,
      );
    });
  });
}
