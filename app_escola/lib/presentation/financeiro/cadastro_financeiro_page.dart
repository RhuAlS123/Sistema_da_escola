import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_error_messages.dart';
import '../../core/format/app_formats.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/domain.dart';
import '../providers/app_providers.dart';

/// PASSOS §5.2 — contrato financeiro, primeiro save bloqueia, admin desbloqueia com senha.
class CadastroFinanceiroPage extends ConsumerStatefulWidget {
  const CadastroFinanceiroPage({super.key});

  @override
  ConsumerState<CadastroFinanceiroPage> createState() =>
      _CadastroFinanceiroPageState();
}

class _CadastroFinanceiroPageState extends ConsumerState<CadastroFinanceiroPage> {
  final _valorTotal = TextEditingController();
  final _valorEntrada = TextEditingController();
  final _taxas = TextEditingController();
  final _jurosDiario = TextEditingController();
  final _refValorMensalPromo = TextEditingController();
  final _refValorMensalIntegral = TextEditingController();
  final _duracaoMeses = TextEditingController();
  final _pacoteOutros = TextEditingController();
  final _observacao = TextEditingController();
  final _turmaHorarioTec = TextEditingController();
  final _turmaHorarioIng = TextEditingController();

  DateTime? _dataMatricula;
  DateTime? _dataPrimeiroVencimento;
  String _pacoteLabel = FinanceiroContrato.pacotesPredefinidos.first;
  bool _turmaTecnologia = false;
  bool _turmaIngles = false;
  String _statusContrato = FinanceiroContrato.statusMensalista;

  String? _nomeAluno;
  String? _nomeResponsavel;
  bool _existeFinanceiroSalvo = false;
  bool _locked = false;
  bool _carregando = false;
  bool _salvando = false;
  bool _excluindo = false;

  static final _moneyFmt = NumberFormat('#,##0.00', 'pt_BR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _carregar(ref.read(alunoSelecionadoIdProvider));
    });
  }

  @override
  void dispose() {
    _valorTotal.dispose();
    _valorEntrada.dispose();
    _taxas.dispose();
    _jurosDiario.dispose();
    _refValorMensalPromo.dispose();
    _refValorMensalIntegral.dispose();
    _duracaoMeses.dispose();
    _pacoteOutros.dispose();
    _observacao.dispose();
    _turmaHorarioTec.dispose();
    _turmaHorarioIng.dispose();
    super.dispose();
  }

  double? _parseMoney(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll(RegExp(r'\s'), '');
    if (s.contains(',')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  int? _parseIntSafe(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  String _doubleParaCampo(double v) => _moneyFmt.format(v);

  Future<void> _carregar(String? alunoId) async {
    if (alunoId == null) {
      setState(() {
        _nomeAluno = null;
        _nomeResponsavel = null;
        _existeFinanceiroSalvo = false;
        _locked = false;
        _limparForm();
      });
      return;
    }

    setState(() => _carregando = true);
    try {
      final repo = ref.read(alunoRepositoryProvider);
      final dados = await repo.obterDadosPessoais(alunoId);
      final fin = await repo.obterFinanceiro(alunoId);
      if (!mounted) return;
      setState(() {
        _nomeAluno = dados?.nomeAluno ?? '(sem nome)';
        _nomeResponsavel = dados?.nomeResponsavel ?? '(sem nome)';
        if (fin != null) {
          _existeFinanceiroSalvo = true;
          _locked = fin.isLocked;
          _dataMatricula = fin.dataMatricula;
          _dataPrimeiroVencimento = fin.dataPrimeiroVencimento;
          _pacoteLabel = FinanceiroContrato.pacotesPredefinidos.contains(fin.pacoteLabel)
              ? fin.pacoteLabel
              : FinanceiroContrato.pacoteOutros;
          _pacoteOutros.text = fin.pacoteLabel == FinanceiroContrato.pacoteOutros
              ? fin.pacoteOutrosDetalhe
              : '';
          _turmaTecnologia = fin.turmaTecnologia;
          _turmaIngles = fin.turmaIngles;
          _turmaHorarioTec.text = fin.turmaHorarioTecnologia;
          _turmaHorarioIng.text = fin.turmaHorarioIngles;
          _duracaoMeses.text = '${fin.duracaoMeses}';
          _valorTotal.text = _doubleParaCampo(fin.valorTotal);
          _valorEntrada.text = _doubleParaCampo(fin.valorEntrada);
          _taxas.text = _doubleParaCampo(fin.taxas);
          _jurosDiario.text = _doubleParaCampo(fin.jurosDiario);
          _refValorMensalPromo.text = _doubleParaCampo(fin.refValorMensalPromo);
          _refValorMensalIntegral.text =
              _doubleParaCampo(fin.refValorMensalIntegral);
          _statusContrato = fin.statusContrato == FinanceiroContrato.statusBolsista
              ? FinanceiroContrato.statusBolsista
              : FinanceiroContrato.statusMensalista;
          _observacao.text = fin.observacao;
        } else {
          _existeFinanceiroSalvo = false;
          _locked = false;
          _limparForm();
          final hoje = DateTime.now();
          final dia = DateTime(hoje.year, hoje.month, hoje.day);
          _dataMatricula = dia;
          _dataPrimeiroVencimento = dia;
        }
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _limparForm() {
    _valorTotal.clear();
    _valorEntrada.clear();
    _taxas.text = _doubleParaCampo(0);
    _jurosDiario.text = _doubleParaCampo(0);
    _refValorMensalPromo.text = _doubleParaCampo(0);
    _refValorMensalIntegral.text = _doubleParaCampo(0);
    _duracaoMeses.text = '12';
    _pacoteOutros.clear();
    _observacao.clear();
    _pacoteLabel = FinanceiroContrato.pacotesPredefinidos.first;
    _turmaTecnologia = false;
    _turmaIngles = false;
    _turmaHorarioTec.clear();
    _turmaHorarioIng.clear();
    _statusContrato = FinanceiroContrato.statusMensalista;
    _dataMatricula = null;
    _dataPrimeiroVencimento = null;
  }

  FinanceiroContrato _montarContrato({required bool isLocked}) {
    final vt = _parseMoney(_valorTotal.text) ?? 0;
    final ve = _parseMoney(_valorEntrada.text) ?? 0;
    final tx = _parseMoney(_taxas.text) ?? 0;
    final juros = _parseMoney(_jurosDiario.text) ?? 0;
    final refPromo = _parseMoney(_refValorMensalPromo.text) ?? 0;
    final refIntegral = _parseMoney(_refValorMensalIntegral.text) ?? 0;
    final dm = _parseIntSafe(_duracaoMeses.text) ?? 1;
    final dmMat = _dataMatricula ?? DateTime.now();
    final dmVen = _dataPrimeiroVencimento ?? DateTime.now();
    final pacote = _pacoteLabel;
    final detalhe =
        pacote == FinanceiroContrato.pacoteOutros ? _pacoteOutros.text.trim() : '';

    return FinanceiroContrato(
      dataMatricula: dmMat,
      pacoteLabel: pacote,
      pacoteOutrosDetalhe: detalhe,
      turmaTecnologia: _turmaTecnologia,
      turmaIngles: _turmaIngles,
      turmaHorarioTecnologia: _turmaHorarioTec.text.trim(),
      turmaHorarioIngles: _turmaHorarioIng.text.trim(),
      dataPrimeiroVencimento: dmVen,
      duracaoMeses: dm,
      valorTotal: vt,
      valorEntrada: ve,
      taxas: tx,
      jurosDiario: juros,
      refValorMensalPromo: refPromo,
      refValorMensalIntegral: refIntegral,
      statusContrato: _statusContrato,
      observacao: _observacao.text.trim(),
      isLocked: isLocked,
    );
  }

  Future<void> _salvarEGerar() async {
    final alunoId = ref.read(alunoSelecionadoIdProvider);
    if (alunoId == null) return;

    final primeiroSave = !_existeFinanceiroSalvo;
    final c = _montarContrato(
      isLocked: primeiroSave ? true : _locked,
    );

    if (!c.podeSalvarEGerarParcelas) {
      final String msg;
      if (!c.turmasHorariosValidos) {
        msg = 'Se marcar Tecnologia ou Inglês, preencha turma e horário desse curso.';
      } else if (!c.pacoteOutrosValido) {
        msg = 'Descreva o pacote quando selecionar «Outros».';
      } else if (!c.podeSalvarContratoBasico) {
        msg = 'Preencha matrícula, vencimento, duração (1–120), valores e status. '
            'Entrada + taxas não podem exceder o total.';
      } else {
        msg = 'Saldo a parcelar ou duração inválidos para gerar parcelas.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      await ref.read(alunoRepositoryProvider).salvarFinanceiroGerarParcelas(
            alunoId: alunoId,
            financeiro: c,
          );
      if (!mounted) return;
      setState(() {
        _existeFinanceiroSalvo = true;
        _locked = c.isLocked;
      });
      ref.read(mainTabIndexProvider.notifier).state = 2;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            primeiroSave
                ? 'Contrato salvo e bloqueado '
                    '${c.saldoFinanciado > 0 ? '${c.duracaoMeses} parcelas geradas.' : 'Sem parcelas (à vista ou saldo zero).'}'
                : 'Contrato atualizado e parcelas recalculadas.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErroParaUsuario(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _bloquearManual() async {
    final alunoId = ref.read(alunoSelecionadoIdProvider);
    if (alunoId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bloquear edição'),
        content: const Text(
          'Travar o contrato até o administrador desbloquear com senha?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(alunoRepositoryProvider).definirBloqueioFinanceiro(
            alunoId: alunoId,
            locked: true,
          );
      if (!mounted) return;
      setState(() => _locked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contrato bloqueado.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErroParaUsuario(e))),
        );
      }
    }
  }

  Future<void> _excluirAlunoFirestore() async {
    final alunoId = ref.read(alunoSelecionadoIdProvider);
    if (alunoId == null) return;
    final nome = _nomeAluno ?? alunoId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir aluno'),
        content: Text(
          'Apagar permanentemente o cadastro de «$nome» e todas as parcelas '
          'no Firestore? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _excluindo = true);
    try {
      await ref.read(alunoRepositoryProvider).excluirAluno(alunoId);
      if (!mounted) return;
      ref.read(alunoSelecionadoIdProvider.notifier).state = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aluno excluído do Firestore.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErroParaUsuario(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  Future<void> _desbloquear() async {
    final alunoId = ref.read(alunoSelecionadoIdProvider);
    if (alunoId == null) return;

    final senha = await showDialog<String>(
      context: context,
      builder: (ctx) => const _DesbloquearSenhaDialog(),
    );
    if (senha == null || senha.isEmpty || !mounted) return;

    try {
      await ref.read(authRepositoryProvider).reauthenticateWithPassword(senha);
      await ref.read(alunoRepositoryProvider).definirBloqueioFinanceiro(
            alunoId: alunoId,
            locked: false,
          );
      if (!mounted) return;
      setState(() => _locked = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Desbloqueado. Você pode editar e salvar.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErroParaUsuario(e))),
        );
      }
    }
  }

  Future<void> _pickData({required bool matricula}) async {
    final hoje = DateTime.now();
    final atual = matricula ? _dataMatricula : _dataPrimeiroVencimento;
    final d = await showDatePicker(
      context: context,
      locale: kAppLocale,
      initialDate: atual ?? hoje,
      firstDate: DateTime(hoje.year - 5),
      lastDate: DateTime(hoje.year + 6),
      initialEntryMode: matricula
          ? DatePickerEntryMode.calendar
          : DatePickerEntryMode.input,
      helpText: matricula
          ? 'Data da matrícula'
          : 'Primeiro vencimento (dia, mês e ano)',
      fieldHintText: matricula ? null : 'DD/MM/AAAA',
    );
    if (d != null) {
      setState(() {
        if (matricula) {
          _dataMatricula = d;
        } else {
          _dataPrimeiroVencimento = d;
        }
      });
    }
  }

  Future<void> _abrirLocalizar() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return _LocalizarAlunoFinanceiroSheet(
          onEscolhido: (id) async {
            Navigator.pop(ctx);
            ref.read(alunoSelecionadoIdProvider.notifier).state = id;
          },
        );
      },
    );
  }

  /// Cenário alinhado aos exemplos da regra (promo ×2 integral, juros R\$ 0,10/dia corrido).
  void _preencherExemploDemonstracao() {
    if (_locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Desbloqueie o contrato para usar o preenchimento de demonstração.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _pacoteLabel = FinanceiroContrato.pacotesPredefinidos.first;
      _pacoteOutros.clear();
      _turmaTecnologia = false;
      _turmaIngles = false;
      _turmaHorarioTec.clear();
      _turmaHorarioIng.clear();
      _dataMatricula = DateTime(2026, 1, 10);
      _dataPrimeiroVencimento = DateTime(2026, 1, 17);
      _duracaoMeses.text = '12';
      _valorTotal.text = _doubleParaCampo(1200);
      _valorEntrada.text = _doubleParaCampo(0);
      _taxas.text = _doubleParaCampo(0);
      _jurosDiario.text = _doubleParaCampo(0.10);
      _refValorMensalPromo.text = _doubleParaCampo(100);
      _refValorMensalIntegral.text = _doubleParaCampo(200);
      _observacao.text =
          'Demonstração ao cliente: 12 parcelas de R\$ 100 (promo) com integral '
          'R\$ 200; juros R\$ 0,10 por dia corrido após perder o promocional; '
          '1º vencimento em sábado 17/01/2026.';
      _statusContrato = FinanceiroContrato.statusMensalista;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Exemplo aplicado. Salve o contrato para gerar as parcelas e mostrar o Controle de parcelas.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alunoId = ref.watch(alunoSelecionadoIdProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    ref.listen<String?>(alunoSelecionadoIdProvider, (prev, next) {
      if (prev != next) _carregar(next);
    });

    final role = profile?.role;
    final somenteLeituraColab = _locked && role == UserRole.colab;

    if (alunoId == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum aluno selecionado',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cadastre ou localize um aluno na guia Cadastro geral e use '
                  '"Salvar e ir para Cadastro financeiro".',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(mainTabIndexProvider.notifier).state = 0,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Ir para Cadastro geral'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_carregando && _nomeAluno == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _abrirLocalizar,
                    icon: const Icon(Icons.search),
                    label: const Text('Localizar aluno'),
                  ),
                  const SizedBox(width: 12),
                  if (_locked)
                    Icon(
                      Icons.lock_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              if (!_locked) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _preencherExemploDemonstracao,
                    icon: const Icon(Icons.slideshow_outlined),
                    label: const Text('Preencher exemplo (demonstração ao cliente)'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Responsável (somente leitura)', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                child: Text(_nomeResponsavel ?? '—'),
              ),
              const SizedBox(height: 12),
              Text('Aluno (somente leitura)', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                child: Text(_nomeAluno ?? '—'),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: $alunoId',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_locked) ...[
                const SizedBox(height: 12),
                Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            somenteLeituraColab
                                ? 'Bloqueado. Somente administrador desbloqueia (ícone cadeado / senha).'
                                : 'Bloqueado. Use Desbloquear e confirme sua senha de administrador.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _locked ? null : () => _pickData(matricula: true),
                  icon: const Icon(Icons.school_outlined),
                  label: Text(
                    'Data da matrícula: '
                    '${_dataMatricula != null ? kAppDateFormat.format(_dataMatricula!) : "Selecionar"}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey('pacote_$alunoId$_pacoteLabel'),
                initialValue: _pacoteLabel,
                decoration: const InputDecoration(
                  labelText: 'Pacote',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final p in FinanceiroContrato.pacotesPredefinidos)
                    DropdownMenuItem(value: p, child: Text(p)),
                ],
                onChanged: _locked
                    ? null
                    : (v) => setState(() => _pacoteLabel = v ?? _pacoteLabel),
              ),
              if (_pacoteLabel == FinanceiroContrato.pacoteOutros) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pacoteOutros,
                  readOnly: _locked,
                  decoration: const InputDecoration(
                    labelText: 'Descreva o pacote (Outros)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text('TURMAS', style: AppTheme.sectionHeader(context)),
              CheckboxListTile(
                value: _turmaTecnologia,
                onChanged: _locked
                    ? null
                    : (v) => setState(() {
                          _turmaTecnologia = v ?? false;
                          if (!_turmaTecnologia) _turmaHorarioTec.clear();
                        }),
                title: const Text('Tecnologia'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_turmaTecnologia) ...[
                TextFormField(
                  controller: _turmaHorarioTec,
                  readOnly: _locked,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Turma / horário — Tecnologia',
                    hintText: 'Ex.: 3ª feira 14h–16h ou Turma A manhã',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              CheckboxListTile(
                value: _turmaIngles,
                onChanged: _locked
                    ? null
                    : (v) => setState(() {
                          _turmaIngles = v ?? false;
                          if (!_turmaIngles) _turmaHorarioIng.clear();
                        }),
                title: const Text('Inglês'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_turmaIngles) ...[
                TextFormField(
                  controller: _turmaHorarioIng,
                  readOnly: _locked,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Turma / horário — Inglês',
                    hintText: 'Ex.: Sábado 9h–11h',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _locked ? null : () => _pickData(matricula: false),
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    'Primeiro vencimento: '
                    '${_dataPrimeiroVencimento != null ? kAppDateFormat.format(_dataPrimeiroVencimento!) : "Selecionar"}',
                  ),
                ),
              ),
              if (!_locked)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                  child: Text(
                    'Toque para informar em ordem dia → mês → ano (teclado). '
                    'No calendário, use o ícone para alternar.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _duracaoMeses,
                readOnly: _locked,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Duração (meses)',
                  helperText: 'Número de parcelas = duração (PASSOS §5.2).',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorTotal,
                readOnly: _locked,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Valor total (R\$)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorEntrada,
                readOnly: _locked,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Valor da entrada (R\$)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxas,
                readOnly: _locked,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Taxas (R\$)',
                  border: OutlineInputBorder(),
                  helperText: 'Descontadas do saldo a parcelar (além da entrada).',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jurosDiario,
                readOnly: _locked,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Juros diário (R\$)',
                  border: OutlineInputBorder(),
                  helperText:
                      'Com referências promo/integral abaixo: cobrado por dia corrido '
                      'após perder o promocional. Sem integral: dias úteis; domingos e '
                      'feriados não entram no atraso.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _refValorMensalPromo,
                readOnly: _locked,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Referência: mensal promocional (R\$, opcional)',
                  border: OutlineInputBorder(),
                  helperText:
                      'Junto com «mensal cheia», define o fator integral÷promo em cada parcela gerada.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _refValorMensalIntegral,
                readOnly: _locked,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Referência: mensal cheia / perda promocional (R\$, opcional)',
                  border: OutlineInputBorder(),
                  helperText:
                      'Deve ser maior que o promocional. Ex.: promo 100 e cheia 200 → fator 2×.',
                ),
              ),
              Builder(
                builder: (context) {
                  final vt = _parseMoney(_valorTotal.text) ?? 0;
                  final ve = _parseMoney(_valorEntrada.text) ?? 0;
                  final tx = _parseMoney(_taxas.text) ?? 0;
                  final saldo = vt - ve - tx;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      saldo > 0
                          ? 'Saldo a parcelar: ${_moneyFmt.format(saldo)} '
                              '(${_duracaoMeses.text.trim().isEmpty ? "—" : _duracaoMeses.text} parcelas)'
                          : saldo == 0 && vt >= 0
                              ? 'Sem saldo a parcelar (à vista ou taxas/entrada cobrem o total).'
                              : 'Ajuste total, entrada e taxas.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('status_$alunoId$_statusContrato'),
                initialValue: _statusContrato,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: FinanceiroContrato.statusMensalista,
                    child: Text('Mensalista'),
                  ),
                  DropdownMenuItem(
                    value: FinanceiroContrato.statusBolsista,
                    child: Text('Bolsista'),
                  ),
                ],
                onChanged: _locked
                    ? null
                    : (v) => setState(
                          () => _statusContrato = v ?? _statusContrato,
                        ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacao,
                readOnly: _locked,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação (status ou notas)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: (_salvando || _locked) ? null : _salvarEGerar,
                    icon: _salvando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Salvar e gerar parcelas'),
                  ),
                  if (_existeFinanceiroSalvo && !_locked)
                    OutlinedButton.icon(
                      onPressed: _bloquearManual,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Bloquear'),
                    ),
                  if (role == UserRole.admin)
                    OutlinedButton.icon(
                      onPressed: (_salvando || _excluindo) ? null : _excluirAlunoFirestore,
                      icon: _excluindo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline),
                      label: const Text('Excluir aluno'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF9A2E2E),
                        side: const BorderSide(color: Color(0xFFC45C5C)),
                      ),
                    ),
                  if (_locked && role == UserRole.admin)
                    OutlinedButton.icon(
                      onPressed: _desbloquear,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Desbloquear (senha admin)'),
                    ),
                ],
              ),
              if (role == UserRole.colab)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Exclusão de aluno: apenas o utilizador com role admin no Firestore.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalizarAlunoFinanceiroSheet extends ConsumerStatefulWidget {
  const _LocalizarAlunoFinanceiroSheet({required this.onEscolhido});

  final void Function(String id) onEscolhido;

  @override
  ConsumerState<_LocalizarAlunoFinanceiroSheet> createState() =>
      _LocalizarAlunoFinanceiroSheetState();
}

class _LocalizarAlunoFinanceiroSheetState
    extends ConsumerState<_LocalizarAlunoFinanceiroSheet> {
  final _filtro = TextEditingController();

  @override
  void dispose() {
    _filtro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(alunosResumoProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Localizar aluno', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _filtro,
            decoration: const InputDecoration(
              labelText: 'Filtrar por nome',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.filter_list),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: async.when(
              data: (lista) {
                final q = _filtro.text.trim().toLowerCase();
                final filtrada = q.isEmpty
                    ? lista
                    : lista
                        .where(
                          (a) =>
                              a.nomeAluno.toLowerCase().contains(q) ||
                              a.nomeResponsavel.toLowerCase().contains(q),
                        )
                        .toList();
                if (filtrada.isEmpty) {
                  return const Center(child: Text('Nenhum resultado.'));
                }
                return ListView.builder(
                  itemCount: filtrada.length,
                  itemBuilder: (ctx, i) {
                    final a = filtrada[i];
                    return ListTile(
                      title: Text(a.nomeAluno),
                      subtitle: Text(a.nomeResponsavel),
                      onTap: () => widget.onEscolhido(a.id),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    mensagemErroParaUsuario(e),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesbloquearSenhaDialog extends StatefulWidget {
  const _DesbloquearSenhaDialog();

  @override
  State<_DesbloquearSenhaDialog> createState() => _DesbloquearSenhaDialogState();
}

class _DesbloquearSenhaDialogState extends State<_DesbloquearSenhaDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Desbloquear (administrador)'),
      content: TextField(
        controller: _ctrl,
        decoration: const InputDecoration(
          labelText: 'Senha do administrador',
          border: OutlineInputBorder(),
        ),
        obscureText: true,
        onSubmitted: (_) => Navigator.pop(context, _ctrl.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
