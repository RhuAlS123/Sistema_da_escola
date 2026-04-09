import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_error_messages.dart';
import '../../domain/domain.dart';
import '../providers/app_providers.dart';

/// PASSOS §5.3 — edição por parcela, cores e persistência na subcoleção.
class ControleParcelasPage extends ConsumerWidget {
  const ControleParcelasPage({super.key});

  static final _dataFmt = DateFormat('dd/MM/yyyy');
  static final _moneyFmt = NumberFormat('#,##0.00', 'pt_BR');

  static Color _corStatus(
    BuildContext context,
    ParcelaStatusVisual s,
  ) {
    final cs = Theme.of(context).colorScheme;
    return switch (s) {
      ParcelaStatusVisual.pago => cs.tertiaryContainer,
      ParcelaStatusVisual.aberto => cs.secondaryContainer,
      ParcelaStatusVisual.atrasado => cs.errorContainer,
    };
  }

  static Color _corStatusOn(
    BuildContext context,
    ParcelaStatusVisual s,
  ) {
    final cs = Theme.of(context).colorScheme;
    return switch (s) {
      ParcelaStatusVisual.pago => cs.onTertiaryContainer,
      ParcelaStatusVisual.aberto => cs.onSecondaryContainer,
      ParcelaStatusVisual.atrasado => cs.onErrorContainer,
    };
  }

  static String _rotuloStatus(ParcelaStatusVisual s) {
    return switch (s) {
      ParcelaStatusVisual.pago => 'Pago',
      ParcelaStatusVisual.aberto => 'Aberto',
      ParcelaStatusVisual.atrasado => 'Atrasado',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunoId = ref.watch(alunoSelecionadoIdProvider);
    final perfil = ref.watch(userProfileProvider).valueOrNull;

    if (alunoId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecione um aluno no Cadastro geral e conclua o financeiro.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final async = ref.watch(parcelasDoAlunoProvider(alunoId));

    return async.when(
      data: (lista) {
        if (lista.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Nenhuma parcela. Salve o contrato em Cadastro financeiro.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }
        final agora = DateTime.now();
        final hoje = DateTime(agora.year, agora.month, agora.day);
        final finAsync = ref.watch(financeiroContratoDoAlunoProvider(alunoId));
        final jurosDiario = finAsync.valueOrNull?.jurosDiario ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lista.length} parcelas — aluno: $alunoId',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Valor devido usa juros por dia útil do contrato (domingos/feriados excluídos do atraso).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: lista.length,
                itemBuilder: (context, i) {
                  final p = lista[i];
                  final vis = resolverParcelaStatusVisual(p, agora);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: _ParcelaEditorTile(
                      parcela: p,
                      alunoId: alunoId,
                      statusVisual: vis,
                      corFundo: _corStatus(context, vis),
                      corConteudo: _corStatusOn(context, vis),
                      rotuloStatus: _rotuloStatus(vis),
                      nomeAtendentePadrao: perfil?.nome ?? '',
                      dataFmt: _dataFmt,
                      moneyFmt: _moneyFmt,
                      jurosDiarioContrato: jurosDiario,
                      referenciaCalculo: hoje,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            mensagemErroParaUsuario(e),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}

const _formasPagamento = <String>[
  '',
  'PIX',
  'Dinheiro',
  'Cartão débito',
  'Cartão crédito',
  'Boleto',
  'Transferência',
  'Outros',
];

class _ParcelaEditorTile extends ConsumerStatefulWidget {
  const _ParcelaEditorTile({
    required this.parcela,
    required this.alunoId,
    required this.statusVisual,
    required this.corFundo,
    required this.corConteudo,
    required this.rotuloStatus,
    required this.nomeAtendentePadrao,
    required this.dataFmt,
    required this.moneyFmt,
    required this.jurosDiarioContrato,
    required this.referenciaCalculo,
  });

  final ParcelaGerada parcela;
  final String alunoId;
  final ParcelaStatusVisual statusVisual;
  final Color corFundo;
  final Color corConteudo;
  final String rotuloStatus;
  final String nomeAtendentePadrao;
  final DateFormat dataFmt;
  final NumberFormat moneyFmt;
  final double jurosDiarioContrato;
  final DateTime referenciaCalculo;

  @override
  ConsumerState<_ParcelaEditorTile> createState() =>
      _ParcelaEditorTileState();
}

class _ParcelaEditorTileState extends ConsumerState<_ParcelaEditorTile> {
  late final TextEditingController _valorPago;
  late final TextEditingController _cartaoParcelas;
  late final TextEditingController _cartaoTaxa;
  late final TextEditingController _atendente;
  late String _forma;
  DateTime? _dataPagamento;

  double? _parseMoney(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll(RegExp(r'\s'), '');
    if (s.contains(',')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  @override
  void initState() {
    super.initState();
    _valorPago = TextEditingController(
      text: widget.moneyFmt.format(widget.parcela.valorPago),
    );
    _cartaoParcelas = TextEditingController(
      text: widget.parcela.cartaoParcelas != null
          ? '${widget.parcela.cartaoParcelas}'
          : '',
    );
    _cartaoTaxa = TextEditingController(
      text: widget.parcela.cartaoTaxaPct > 0
          ? widget.parcela.cartaoTaxaPct.toStringAsFixed(2)
          : '',
    );
    _atendente = TextEditingController(
      text: widget.parcela.atendente.isNotEmpty
          ? widget.parcela.atendente
          : widget.nomeAtendentePadrao,
    );
    _forma = _formasPagamento.contains(widget.parcela.formaPagamento)
        ? widget.parcela.formaPagamento
        : (widget.parcela.formaPagamento.isEmpty ? '' : 'Outros');
    _dataPagamento = widget.parcela.dataPagamento;
  }

  @override
  void didUpdateWidget(covariant _ParcelaEditorTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parcela.valorPago != widget.parcela.valorPago) {
      _valorPago.text = widget.moneyFmt.format(widget.parcela.valorPago);
    }
    if (oldWidget.parcela.dataPagamento != widget.parcela.dataPagamento) {
      _dataPagamento = widget.parcela.dataPagamento;
    }
  }

  @override
  void dispose() {
    _valorPago.dispose();
    _cartaoParcelas.dispose();
    _cartaoTaxa.dispose();
    _atendente.dispose();
    super.dispose();
  }

  bool get _mostrarCartaoCredito => _forma == 'Cartão crédito';

  Future<void> _pickPagamento() async {
    final hoje = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dataPagamento ?? hoje,
      firstDate: DateTime(hoje.year - 2),
      lastDate: DateTime(hoje.year + 1),
    );
    if (d != null) setState(() => _dataPagamento = d);
  }

  Future<void> _salvar() async {
    final vp = _parseMoney(_valorPago.text) ?? 0;
    final taxa = double.tryParse(
          _cartaoTaxa.text.trim().replaceAll(',', '.'),
        ) ??
        0;
    final cx = int.tryParse(_cartaoParcelas.text.trim());

    final atual = widget.parcela.copyWith(
      valorPago: vp,
      dataPagamento: _dataPagamento,
      formaPagamento: _forma,
      cartaoParcelas: _mostrarCartaoCredito ? cx : null,
      cartaoTaxaPct: _mostrarCartaoCredito ? taxa : 0,
      atendente: _atendente.text.trim(),
    );

    if (vp > 0 && atual.dataPagamento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe a data de pagamento quando houver valor pago.'),
        ),
      );
      return;
    }

    try {
      await ref.read(alunoRepositoryProvider).salvarParcela(
            alunoId: widget.alunoId,
            parcela: atual,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parcela ${widget.parcela.numero} salva.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErroParaUsuario(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.parcela;
    final vp = _parseMoney(_valorPago.text) ?? p.valorPago;
    final feriados = feriadosParaCalculo(
      a: p.vencimento,
      b: widget.referenciaCalculo,
    );
    final diasUteis = diasUteisAtraso(
      vencimento: p.vencimento,
      fim: widget.referenciaCalculo,
      feriados: feriados,
    );
    final restante = restanteParcelaComJuros(
      parcela: p,
      valorPago: vp,
      referencia: widget.referenciaCalculo,
      jurosDiarioContrato: widget.jurosDiarioContrato,
    );

    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: widget.corFundo,
        foregroundColor: widget.corConteudo,
        child: Text(
          '${p.numero}',
          style: TextStyle(
            color: widget.corConteudo,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text('Venc. ${widget.dataFmt.format(p.vencimento)} — R\$ ${widget.moneyFmt.format(p.valor)}'),
      subtitle: Chip(
        label: Text(widget.rotuloStatus),
        backgroundColor: widget.corFundo,
        labelStyle: TextStyle(color: widget.corConteudo, fontSize: 12),
        padding: EdgeInsets.zero,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.statusVisual != ParcelaStatusVisual.pago) ...[
                Text(
                  'Dias úteis de atraso (até hoje): $diasUteis — juros/dia útil: '
                  'R\$ ${widget.moneyFmt.format(widget.jurosDiarioContrato)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Restante (mensalidade + juros − perda − pago): R\$ '
                  '${widget.moneyFmt.format(restante)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ] else
                Text(
                  'Parcela quitada.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _valorPago,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Valor pago (R\$)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickPagamento,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    'Data pagamento: '
                    '${_dataPagamento != null ? widget.dataFmt.format(_dataPagamento!) : "Selecionar"}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey('forma_${p.numero}_$_forma'),
                initialValue: _forma.isEmpty ? null : _forma,
                decoration: const InputDecoration(
                  labelText: 'Forma de pagamento',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('—'),
                  ),
                  for (final f in _formasPagamento.where((x) => x.isNotEmpty))
                    DropdownMenuItem(value: f, child: Text(f)),
                ],
                onChanged: (v) => setState(() => _forma = v ?? ''),
              ),
              if (_mostrarCartaoCredito) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cartaoParcelas,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Parcelas no cartão',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cartaoTaxa,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Taxa % (crédito)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _atendente,
                decoration: const InputDecoration(
                  labelText: 'Atendente',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar parcela'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
