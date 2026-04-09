import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/domain.dart';

/// Exportação PDF (PASSOS §5.4).
/// Títulos só com ASCII (hífen `-`). Evitar em dash (U+2014): a Helvetica
/// padrão do pacote `pdf` não o desenha bem e aparece quadrado na impressão.
class RelatoriosPdf {
  static Future<void> imprimirDebito(List<RelatorioDebitoItem> itens) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Text(
            'SIS Icpro - Alunos em debito',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          if (itens.isEmpty)
            pw.Text('Nenhum registro.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Aluno',
                'Responsavel',
                'Telefone',
                'Parc. atraso',
                'Dias max',
                'Valor R\$',
              ],
              data: itens
                  .map(
                    (e) => [
                      e.nomeAluno,
                      e.nomeResponsavel,
                      e.telefone,
                      '${e.parcelasEmAtraso}',
                      '${e.diasAtrasoMax}',
                      e.valorTotalRestante.toStringAsFixed(2),
                    ],
                  )
                  .toList(),
            ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static Future<void> imprimirAniversariantes(
    List<RelatorioAniversarianteItem> itens,
    int mes,
    int ano,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Text(
            'SIS Icpro - Aniversariantes ($mes/$ano)',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          if (itens.isEmpty)
            pw.Text('Nenhum registro.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Aluno',
                'Nascimento',
                'Turmas',
              ],
              data: itens
                  .map(
                    (e) => [
                      e.nomeAluno,
                      _fmtData(e.dataNascimento),
                      e.turmasLabel,
                    ],
                  )
                  .toList(),
            ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static Future<void> imprimirPagantes(
    List<RelatorioPaganteMesItem> itens,
    int mes,
    int ano,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Text(
            'SIS Icpro - Pagantes no mes ($mes/$ano)',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          if (itens.isEmpty)
            pw.Text('Nenhum registro.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Aluno',
                'Responsavel',
                'Qtd pagtos',
                'Total R\$',
              ],
              data: itens
                  .map(
                    (e) => [
                      e.nomeAluno,
                      e.nomeResponsavel,
                      '${e.quantidadePagamentos}',
                      e.valorTotalPago.toStringAsFixed(2),
                    ],
                  )
                  .toList(),
            ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static Future<void> imprimirEmDia(
    List<RelatorioEmDiaMesItem> itens,
    int mes,
    int ano,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Text(
            'SIS Icpro - Alunos em dia ($mes/$ano)',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Pagamentos no prazo, sem parcela atrasada hoje.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          if (itens.isEmpty)
            pw.Text('Nenhum registro.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Aluno',
                'Responsavel',
                'Qtd pagtos',
                'Total R\$',
              ],
              data: itens
                  .map(
                    (e) => [
                      e.nomeAluno,
                      e.nomeResponsavel,
                      '${e.quantidadePagamentosEmDia}',
                      e.valorTotalPago.toStringAsFixed(2),
                    ],
                  )
                  .toList(),
            ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static String _fmtData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
