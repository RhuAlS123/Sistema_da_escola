import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../core/errors/app_error_messages.dart';
import '../../domain/domain.dart';
import '../providers/app_providers.dart';

/// PASSOS 5.1 — máscaras, responsável + aluno, idade, Localizar, salvar → financeiro,
/// autosave ao trocar de guia (dados válidos do 1.º passo).
class CadastroGeralPage extends ConsumerStatefulWidget {
  const CadastroGeralPage({super.key});

  @override
  ConsumerState<CadastroGeralPage> createState() => _CadastroGeralPageState();
}

class _CadastroGeralPageState extends ConsumerState<CadastroGeralPage> {
  final _nomeResp = TextEditingController();
  final _tel = TextEditingController();
  final _cpf = TextEditingController();
  final _rg = TextEditingController();
  final _endereco = TextEditingController();
  final _cidade = TextEditingController();
  final _nomeAluno = TextEditingController();

  DateTime? _nascResp;
  DateTime? _nascAluno;

  String _parentesco = parentescoOpcoesIniciais.first;

  String? _editingAlunoId;
  bool _salvando = false;
  bool _dirty = false;

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _telMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _nomeResp.dispose();
    _tel.dispose();
    _cpf.dispose();
    _rg.dispose();
    _endereco.dispose();
    _cidade.dispose();
    _nomeAluno.dispose();
    super.dispose();
  }

  void _marcarDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _novoAluno() {
    ref.read(alunoSelecionadoIdProvider.notifier).state = null;
    setState(() {
      _editingAlunoId = null;
      _dirty = false;
      _nomeResp.clear();
      _tel.clear();
      _cpf.clear();
      _rg.clear();
      _endereco.clear();
      _cidade.clear();
      _nomeAluno.clear();
      _nascResp = null;
      _nascAluno = null;
      _parentesco = parentescoOpcoesIniciais.first;
    });
  }

  Future<void> _abrirLocalizar() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return _LocalizarAlunoSheet(
          onEscolhido: (id) async {
            Navigator.pop(ctx);
            await _carregarAluno(id);
          },
        );
      },
    );
  }

  Future<void> _carregarAluno(String id) async {
    final repo = ref.read(alunoRepositoryProvider);
    final dados = await repo.obterDadosPessoais(id);
    if (!mounted || dados == null) return;
    ref.read(alunoSelecionadoIdProvider.notifier).state = id;
    setState(() {
      _editingAlunoId = id;
      _dirty = false;
      _nomeResp.text = dados.nomeResponsavel;
      _tel.text = dados.telefone;
      _cpf.text = dados.cpf;
      _rg.text = dados.rg;
      _endereco.text = dados.endereco;
      _cidade.text = dados.cidade;
      _nomeAluno.text = dados.nomeAluno;
      _nascResp = dados.dataNascimentoResponsavel;
      _nascAluno = dados.dataNascimentoAluno;
      _parentesco = parentescoOpcoesIniciais.contains(dados.parentesco)
          ? dados.parentesco
          : parentescoOpcoesIniciais.last;
    });
  }

  DadosPessoaisCadastro _montarDados() {
    return DadosPessoaisCadastro(
      nomeResponsavel: _nomeResp.text.trim(),
      telefone: _tel.text.trim(),
      cpf: _cpf.text.trim(),
      rg: _rg.text.trim(),
      dataNascimentoResponsavel: _nascResp,
      endereco: _endereco.text.trim(),
      cidade: _cidade.text.trim(),
      parentesco: _parentesco,
      nomeAluno: _nomeAluno.text.trim(),
      dataNascimentoAluno: _nascAluno,
    );
  }

  Future<bool> _persistirCadastro({required bool navegarParaFinanceiro}) async {
    final dados = _montarDados();
    if (!dados.podeSalvarPrimeiroPasso) return false;

    setState(() => _salvando = true);
    try {
      final repo = ref.read(alunoRepositoryProvider);
      final id = _editingAlunoId;
      if (id == null) {
        final novoId = await repo.criar(dados);
        ref.read(alunoSelecionadoIdProvider.notifier).state = novoId;
        if (mounted) {
          setState(() {
            _editingAlunoId = novoId;
            _dirty = false;
          });
        }
      } else {
        await repo.atualizar(id, dados);
        ref.read(alunoSelecionadoIdProvider.notifier).state = id;
        if (mounted) setState(() => _dirty = false);
      }
      if (!mounted) return true;
      if (navegarParaFinanceiro) {
        ref.read(mainTabIndexProvider.notifier).state = 1;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salvo. Cadastro financeiro — próxima guia.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro geral salvo automaticamente.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErroParaUsuario(e))),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _autosaveSeNecessario() async {
    if (!mounted || !_dirty || _salvando) return;
    final dados = _montarDados();
    if (!dados.podeSalvarPrimeiroPasso) return;
    await _persistirCadastro(navegarParaFinanceiro: false);
  }

  Future<void> _salvar() async {
    final dados = _montarDados();
    if (!dados.podeSalvarPrimeiroPasso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha pelo menos nome do responsável, nome do aluno e data de '
            'nascimento do aluno.',
          ),
        ),
      );
      return;
    }
    await _persistirCadastro(navegarParaFinanceiro: true);
  }

  Future<void> _pickData({required bool responsavel}) async {
    final hoje = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: responsavel
          ? (_nascResp ?? DateTime(hoje.year - 30))
          : (_nascAluno ?? DateTime(hoje.year - 10)),
      firstDate: DateTime(1900),
      lastDate: hoje,
    );
    if (d != null) {
      setState(() {
        if (responsavel) {
          _nascResp = d;
        } else {
          _nascAluno = d;
        }
        _dirty = true;
      });
    }
  }

  String _fmtData(DateTime? d) =>
      d == null ? 'Selecionar' : DateFormat('dd/MM/yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainTabIndexProvider, (prev, next) {
      if (prev != 0 || next == 0) return;
      Future.microtask(() => _autosaveSeNecessario());
    });

    final refDate = DateTime.now();
    final idade = idadeEmAnosCompleta(_nascAluno, refDate);

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
                  FilledButton.tonal(
                    onPressed: _novoAluno,
                    child: const Text('Cadastrar novo aluno'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _abrirLocalizar,
                    icon: const Icon(Icons.search),
                    label: const Text('Localizar aluno'),
                  ),
                ],
              ),
              if (_editingAlunoId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Editando aluno ID: $_editingAlunoId',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              Text('Responsável', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nomeResp,
                onChanged: (_) => _marcarDirty(),
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tel,
                onChanged: (_) => _marcarDirty(),
                inputFormatters: [_telMask],
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cpf,
                onChanged: (_) => _marcarDirty(),
                inputFormatters: [_cpfMask],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CPF',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rg,
                onChanged: (_) => _marcarDirty(),
                decoration: const InputDecoration(
                  labelText: 'RG',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _pickData(responsavel: true),
                  icon: const Icon(Icons.calendar_today),
                  label: Text('Data de nascimento (responsável): ${_fmtData(_nascResp)}'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _endereco,
                onChanged: (_) => _marcarDirty(),
                decoration: const InputDecoration(
                  labelText: 'Endereço',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cidade,
                onChanged: (_) => _marcarDirty(),
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _parentesco,
                decoration: const InputDecoration(
                  labelText: 'Parentesco',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final p in parentescoOpcoesIniciais)
                    DropdownMenuItem(value: p, child: Text(p)),
                ],
                onChanged: (v) {
                  setState(() {
                    _parentesco = v ?? _parentesco;
                    _dirty = true;
                  });
                },
              ),
              const SizedBox(height: 24),
              Text('Aluno', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nomeAluno,
                onChanged: (_) => _marcarDirty(),
                decoration: const InputDecoration(
                  labelText: 'Nome do aluno',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _pickData(responsavel: false),
                  icon: const Icon(Icons.cake_outlined),
                  label: Text(
                    'Data de nascimento (aluno): ${_fmtData(_nascAluno)}',
                  ),
                ),
              ),
              if (idade != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Idade calculada: $idade anos',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Salvar e ir para Cadastro financeiro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalizarAlunoSheet extends ConsumerStatefulWidget {
  const _LocalizarAlunoSheet({required this.onEscolhido});

  final void Function(String id) onEscolhido;

  @override
  ConsumerState<_LocalizarAlunoSheet> createState() =>
      _LocalizarAlunoSheetState();
}

class _LocalizarAlunoSheetState extends ConsumerState<_LocalizarAlunoSheet> {
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
