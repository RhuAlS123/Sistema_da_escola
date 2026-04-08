/// Conteúdo de `alunos/{id}.dados_pessoais` conforme escopo (responsável + aluno).
///
/// Parentesco: valores exibidos no select (podem ser ajustados com o cliente).
class DadosPessoaisCadastro {
  const DadosPessoaisCadastro({
    required this.nomeResponsavel,
    required this.telefone,
    required this.cpf,
    required this.rg,
    this.dataNascimentoResponsavel,
    required this.endereco,
    required this.cidade,
    required this.parentesco,
    required this.nomeAluno,
    required this.dataNascimentoAluno,
  });

  final String nomeResponsavel;
  final String telefone;
  final String cpf;
  final String rg;
  final DateTime? dataNascimentoResponsavel;
  final String endereco;
  final String cidade;
  final String parentesco;
  final String nomeAluno;
  final DateTime? dataNascimentoAluno;

  /// Campos mínimos para o primeiro salvamento (escopo exige cadastro completo;
  /// aqui só bloqueamos o essencial para persistir e seguir ao financeiro).
  bool get podeSalvarPrimeiroPasso =>
      nomeResponsavel.trim().isNotEmpty &&
      nomeAluno.trim().isNotEmpty &&
      dataNascimentoAluno != null;
}

/// Opções iniciais do select de parentesco (escopo pede select, não lista valores).
const parentescoOpcoesIniciais = <String>[
  'Pai',
  'Mãe',
  'Avô(ó)',
  'Tio(a)',
  'Tutor legal',
  'Outro',
];
