import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_error_messages.dart';
import '../../domain/domain.dart';
import '../providers/app_providers.dart';
import 'relatorios_pdf.dart';

/// PASSOS §5.4 — relatórios e PDF.
class RelatoriosPage extends ConsumerWidget {
  const RelatoriosPage({super.key});

  static final _money = NumberFormat('#,##0.00', 'pt_BR');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesRef = ref.watch(relatorioMesReferenciaProvider);
    final perfil = ref.watch(userProfileProvider).valueOrNull;
    final isAdmin = perfil?.role == UserRole.admin;
    final agora = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Relatórios',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Competência (pagantes / em dia):',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<int>(
                    key: ValueKey('mes_${mesRef.year}_${mesRef.month}'),
                    value: mesRef.month,
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(value: m, child: Text('$m')),
                    ],
                    onChanged: (m) {
                      if (m == null) return;
                      ref.read(relatorioMesReferenciaProvider.notifier).state =
                          DateTime(mesRef.year, m);
                    },
                  ),
                  DropdownButton<int>(
                    key: ValueKey('ano_${mesRef.year}'),
                    value: mesRef.year,
                    items: [
                      for (var y = agora.year - 5; y <= agora.year + 2; y++)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (y) {
                      if (y == null) return;
                      ref.read(relatorioMesReferenciaProvider.notifier).state =
                          DateTime(y, mesRef.month);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SecaoDebito(money: _money),
              const SizedBox(height: 16),
              _SecaoAniversariantes(mesAtual: agora.month, anoAtual: agora.year),
              const SizedBox(height: 16),
              _SecaoPagantes(money: _money, mes: mesRef.month, ano: mesRef.year),
              if (isAdmin) ...[
                const SizedBox(height: 16),
                _SecaoEmDia(money: _money, mes: mesRef.month, ano: mesRef.year),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SecaoDebito extends ConsumerWidget {
  const _SecaoDebito({required this.money});

  final NumberFormat money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(relatorioDebitoProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Alunos em débito',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                async.maybeWhen(
                  data: (itens) => FilledButton.icon(
                    onPressed: itens.isEmpty
                        ? null
                        : () => RelatoriosPdf.imprimirDebito(itens),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            async.when(
              data: (itens) {
                if (itens.isEmpty) {
                  return const Text('Nenhum aluno com parcela atrasada.');
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Aluno')),
                      DataColumn(label: Text('Responsável')),
                      DataColumn(label: Text('Telefone')),
                      DataColumn(label: Text('Parc. atraso')),
                      DataColumn(label: Text('Dias máx.')),
                      DataColumn(label: Text('Valor (R\$)')),
                    ],
                    rows: [
                      for (final e in itens)
                        DataRow(
                          cells: [
                            DataCell(Text(e.nomeAluno)),
                            DataCell(Text(e.nomeResponsavel)),
                            DataCell(Text(e.telefone)),
                            DataCell(Text('${e.parcelasEmAtraso}')),
                            DataCell(Text('${e.diasAtrasoMax}')),
                            DataCell(Text(money.format(e.valorTotalRestante))),
                          ],
                        ),
                    ],
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => _RelatorioErro(texto: mensagemErroParaUsuario(e)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecaoAniversariantes extends ConsumerWidget {
  const _SecaoAniversariantes({
    required this.mesAtual,
    required this.anoAtual,
  });

  final int mesAtual;
  final int anoAtual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(relatorioAniversariantesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Aniversariantes do mês atual ($mesAtual/$anoAtual)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                async.maybeWhen(
                  data: (itens) => FilledButton.icon(
                    onPressed: itens.isEmpty
                        ? null
                        : () => RelatoriosPdf.imprimirAniversariantes(
                              itens,
                              mesAtual,
                              anoAtual,
                            ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            async.when(
              data: (itens) {
                if (itens.isEmpty) {
                  return const Text('Nenhum aniversariante neste mês.');
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Aluno')),
                      DataColumn(label: Text('Nascimento')),
                      DataColumn(label: Text('Turmas')),
                    ],
                    rows: [
                      for (final e in itens)
                        DataRow(
                          cells: [
                            DataCell(Text(e.nomeAluno)),
                            DataCell(Text(
                              '${e.dataNascimento.day.toString().padLeft(2, '0')}/'
                              '${e.dataNascimento.month.toString().padLeft(2, '0')}',
                            )),
                            DataCell(Text(e.turmasLabel)),
                          ],
                        ),
                    ],
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => _RelatorioErro(texto: mensagemErroParaUsuario(e)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecaoPagantes extends ConsumerWidget {
  const _SecaoPagantes({
    required this.money,
    required this.mes,
    required this.ano,
  });

  final NumberFormat money;
  final int mes;
  final int ano;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(relatorioPagantesMesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Alunos pagantes (geral) — $mes/$ano',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                async.maybeWhen(
                  data: (itens) => FilledButton.icon(
                    onPressed: itens.isEmpty
                        ? null
                        : () =>
                            RelatoriosPdf.imprimirPagantes(itens, mes, ano),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            async.when(
              data: (itens) {
                if (itens.isEmpty) {
                  return const Text('Nenhum pagamento registrado neste mês.');
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Aluno')),
                      DataColumn(label: Text('Responsável')),
                      DataColumn(label: Text('Qtd pagtos')),
                      DataColumn(label: Text('Total (R\$)')),
                    ],
                    rows: [
                      for (final e in itens)
                        DataRow(
                          cells: [
                            DataCell(Text(e.nomeAluno)),
                            DataCell(Text(e.nomeResponsavel)),
                            DataCell(Text('${e.quantidadePagamentos}')),
                            DataCell(Text(money.format(e.valorTotalPago))),
                          ],
                        ),
                    ],
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => _RelatorioErro(texto: mensagemErroParaUsuario(e)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecaoEmDia extends ConsumerWidget {
  const _SecaoEmDia({
    required this.money,
    required this.mes,
    required this.ano,
  });

  final NumberFormat money;
  final int mes;
  final int ano;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(relatorioEmDiaMesProvider);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Alunos em dia (admin) — $mes/$ano',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                async.maybeWhen(
                  data: (itens) => FilledButton.icon(
                    onPressed: itens.isEmpty
                        ? null
                        : () => RelatoriosPdf.imprimirEmDia(itens, mes, ano),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pagamentos no prazo (data ≤ vencimento), com registro no mês, '
              'e sem parcela atrasada hoje.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            async.when(
              data: (itens) {
                if (itens.isEmpty) {
                  return const Text('Nenhum registro para o filtro.');
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Aluno')),
                      DataColumn(label: Text('Responsável')),
                      DataColumn(label: Text('Qtd pagtos')),
                      DataColumn(label: Text('Total (R\$)')),
                    ],
                    rows: [
                      for (final e in itens)
                        DataRow(
                          cells: [
                            DataCell(Text(e.nomeAluno)),
                            DataCell(Text(e.nomeResponsavel)),
                            DataCell(Text('${e.quantidadePagamentosEmDia}')),
                            DataCell(Text(money.format(e.valorTotalPago))),
                          ],
                        ),
                    ],
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => _RelatorioErro(texto: mensagemErroParaUsuario(e)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatorioErro extends StatelessWidget {
  const _RelatorioErro({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return SelectableText(
      texto,
      style: TextStyle(color: c.error),
    );
  }
}
