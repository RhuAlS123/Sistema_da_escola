/// Referência dos documentos Firestore usados pelo app (PASSOS Fase 2).
/// Mantido alinhado a [AlunoRepository], [UserProfileRepository] e entidades em `domain/`.
///
/// ## `usuarios/{uid}`  (uid = Firebase Auth)
/// Obrigatórios para o app:
/// - `nome` — String
/// - `role` — `"admin"` \| `"colab"`
///
/// ## `alunos/{alunoId}`
/// Exclusão do documento (e subcoleção) só **admin** nas Security Rules; a UI
/// expõe «Excluir aluno» em Cadastro financeiro para `role == admin`.
///
/// - `dados_pessoais` — mapa: `nome_responsavel`, `telefone`, `cpf`, `rg`,
///   `data_nascimento_responsavel`, `endereco`, `cidade`, `parentesco`,
///   `nome_aluno`, `data_nascimento_aluno` (datas como Timestamp)
/// - `financeiro_contrato` — mapa do contrato (ver entidade `FinanceiroContrato`): datas,
///   pacote, turmas, valores, `is_locked`, `juros_diario`, etc.
/// - `criadoEm`, `atualizadoEm` — Timestamp (servidor)
///
/// Legado (migração): `financeiro`, `parcelas_geradas` em lista — preferir subcoleção.
///
/// ## `alunos/{alunoId}/parcelas/{numero}`
/// `numero` como id string do número da parcela. Campos principais:
/// `numero`, `vencimento`, `valor`, `status`, `data_pagamento`, `valor_pago`,
/// `forma_pagamento`, `cartao_parcelas`, `cartao_taxa_pct`, `atendente`,
/// `perda_promocional`.
library;
