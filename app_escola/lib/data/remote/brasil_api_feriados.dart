import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/feriados_brasil.dart';

/// Feriados nacionais via [Brasil API](https://brasilapi.com.br/docs#tag/Feriados),
/// alinhado ao protótipo ICPROV6 (`fetch` em `App.tsx`).
class BrasilApiFeriadosRepository {
  static const _base = 'https://brasilapi.com.br/api/feriados/v1';

  Future<Set<DateTime>> feriadosNacionaisDoAno(int ano) async {
    final uri = Uri.parse('$_base/$ano');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return {};
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! List) return {};
      final out = <DateTime>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final raw = map['date'];
        if (raw is! String) continue;
        final parts = raw.split('-');
        if (parts.length != 3) continue;
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y == null || m == null || d == null) continue;
        out.add(somenteData(DateTime(y, m, d)));
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// União dos feriados da API para [anoInicio]…[anoFim] (inclusive).
  Future<Set<DateTime>> feriadosParaAnos(int anoInicio, int anoFim) async {
    final a0 = anoInicio < anoFim ? anoInicio : anoFim;
    final a1 = anoInicio < anoFim ? anoFim : anoInicio;
    final out = <DateTime>{};
    for (var y = a0; y <= a1; y++) {
      out.addAll(await feriadosNacionaisDoAno(y));
    }
    return out;
  }
}
