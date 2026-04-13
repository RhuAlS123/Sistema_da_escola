import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_error_messages.dart';
import '../../core/format/app_formats.dart';
import '../../domain/domain.dart';
import '../providers/app_providers.dart';

/// PASSOS §5.3 — edição por parcela, cores e persistência na subcoleção.
class ControleParcelasPage extends ConsumerWidget {
  const ControleParcelasPage({super.key});

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
        final feriadosApi =
            ref.watch(feriadosBrasilApiProvider).valueOrNull ?? <DateTime>{};
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
                    'Com valor integral por parcela (promo + cheio): juros são '
                    'por dia corrido após perder o promocional; limite do desconto '
                    'segue vencimento (domingo/feriado → próximo dia útil). '
                    'Sem integral: juros por dia útil (Brasil API + fixos BR).',
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
                  final extras = feriadosApi.isEmpty ? null : feriadosApi;
                  final vis = resolverParcelaStatusVisual(
                    p,
                    agora,
                    jurosDiarioContrato: jurosDiario,
                    feriadosExtras: extras,
                  );
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
                      dataFmt: kAppDateFormat,
                      moneyFmt: _moneyFmt,
                      jurosDiarioContrato: jurosDiario,
                      referenciaCalculo: hoje,
                      feriadosExtras: feriadosApi,
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
    required this.feriadosExtras,
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
  final Set<DateTime> feriadosExtras;

  @override
  ConsumerState<_ParcelaEditorTile> createState() =>
      _ParcelaEditorTileState();
}

class _ParcelaEditorTileState extends ConsumerState<_ParcelaEditorTile> {
  late final TextEditingController _valorPago;
  late final TextEditingController _cartaoParcelas;
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
          : '1',
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
    _atendente.dispose();
    super.dispose();
  }

  bool get _mostrarCartaoCredito => _forma == 'Cartão crédito';

  Future<void> _pickPagamento() async {
    final hoje = DateTime.now();
    final d = await showDatePicker(
      context: context,
      locale: kAppLocale,
      initialDate: _dataPagamento ?? hoje,
      firstDate: DateTime(hoje.year - 2),
      lastDate: DateTime(hoje.year + 1),
      fieldHintText: 'DD/MM/AAAA',
      fieldLabelText: 'Digite a data',
      errorFormatText: 'Formato inválido. Use DD/MM/AAAA.',
      errorInvalidText: 'Data inválida.',
    );
    if (d != null) setState(() => _dataPagamento = d);
  }

  Future<void> _salvar() async {
    final vp = _parseMoney(_valorPago.text) ?? 0;
    final cx = int.tryParse(_cartaoParcelas.text.trim());
    final taxaFixa = _mostrarCartaoCredito
        ? taxaCartaoCreditoIcproReais(cx)
        : 0.0;

    final atual = widget.parcela.copyWith(
      valorPago: vp,
      dataPagamento: _dataPagamento,
      formaPagamento: _forma,
      cartaoParcelas: _mostrarCartaoCredito ? cx : null,
      cartaoTaxaPct: 0,
      cartaoTaxaFixaReais: taxaFixa,
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
            jurosDiarioContrato: widget.jurosDiarioContrato,
            feriadosExtras: widget.feriadosExtras,
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
    final extras =
        widget.feriadosExtras.isEmpty ? null : widget.feriadosExtras;
    final feriados = feriadosParaCalculo(
      a: p.vencimento,
      b: widget.referenciaCalculo,
      feriadosExtras: extras,
    );
    final diasUteis = diasUteisAtraso(
      vencimento: p.vencimento,
      fim: widget.referenciaCalculo,
      feriados: feriados,
    );
    final doisDegraus = parcelaUsaDoisDegrausPromocionais(p);
    final diasCorridosAtraso = diasAtrasoCalendarioVenctoOriginal(
      p.vencimento,
      widget.referenciaCalculo,
    );
    final devidoBase = valorDevidoParcelaNaData(
      parcela: p,
      referencia: widget.referenciaCalculo,
      jurosDiarioContrato: widget.jurosDiarioContrato,
      feriadosExtras: extras,
    );
    final taxaExibir = _mostrarCartaoCredito
        ? taxaCartaoCreditoIcproReais(int.tryParse(_cartaoParcelas.text.trim()))
        : (formaPagamentoCartaoCredito(p.formaPagamento)
            ? p.cartaoTaxaFixaReais
            : 0.0);
    final restante =
        (devidoBase + taxaExibir - vp).clamp(0.0, double.infinity);

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
      title: Text(
        doisDegraus
            ? 'Venc. ${widget.dataFmt.format(p.vencimento)} — '
                'promo R\$ ${widget.moneyFmt.format(p.valor)} · '
                'integral R\$ ${widget.moneyFmt.format(p.valorIntegral)}'
            : 'Venc. ${widget.dataFmt.format(p.vencimento)} — '
                'R\$ ${widget.moneyFmt.format(p.valor)}',
      ),
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
                  doisDegraus
                      ? 'Dias corridos após vencimento original (até hoje): '
                          '$diasCorridosAtraso — juros/dia: '
                          'R\$ ${widget.moneyFmt.format(widget.jurosDiarioContrato)} '
                          '(após perder o promocional).'
                      : 'Dias úteis de atraso (até hoje): $diasUteis — juros/dia útil: '
                          'R\$ ${widget.moneyFmt.format(widget.jurosDiarioContrato)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Restante (valor devido + taxa cartão ICPRO quando aplicável − pago): '
                  'R\$ ${widget.moneyFmt.format(restante)}',
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
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  'Taxa fixa (ICPRO): R\$ 5,00 × parcelas = '
                  'R\$ ${widget.moneyFmt.format(taxaCartaoCreditoIcproReais(int.tryParse(_cartaoParcelas.text.trim())))}',
                  style: Theme.of(context).textTheme.bodySmall,
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
