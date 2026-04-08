# Passos de implementação — Sistema de gestão escolar (Flutter + Firebase)

Checklist em ordem sugerida. Marque os itens conforme for concluindo.

---

## Fase 0 — Ambiente e contas

- [ ] Instalar Flutter SDK estável e validar com `flutter doctor` *(validar na sua máquina; no ambiente de edição o comando `flutter` pode não estar no PATH)*.
- [ ] Instalar/editar Android Studio ou VS Code com extensões Dart/Flutter.
- [ ] Criar projeto no [Firebase Console](https://console.firebase.google.com/) (nome do app alinhado ao cliente).
- [ ] Registrar apps: **Web**, **Android** e **iOS** (baixar `google-services.json` / `GoogleService-Info.plist` quando for o momento).
- [ ] Habilitar **Authentication** (email/senha ou método escolhido para mapear os 3 usuários fixos).
- [ ] Habilitar **Cloud Firestore** (modo de teste inicialmente; depois regras de segurança).
- [x] Código: `initializeAppFirebase()` + `lib/firebase_options.dart` gerado pelo FlutterFire (`app-escola-fda78`, plataformas **web** e **android**; iOS: rodar `flutterfire configure` num Mac com pasta `ios`).
- [ ] (Opcional) Habilitar **Cloud Functions** se a lógica crítica for no servidor.

---

## Fase 1 — Projeto Flutter e arquitetura

- [ ] Garantir que o app abre em **Chrome (web)** e em **emulador/dispositivo Android** (e iOS se tiver Mac).
- [x] Adicionar dependências no `pubspec.yaml`: `firebase_core`, `cloud_firestore`, `firebase_auth`, `mask_text_input_formatter`, `intl`, `pdf`, `printing`, `flutter_riverpod` — executar `flutter pub get` em `app_escola/`.
- [x] Estrutura inicial **Clean Architecture** em `app_escola/lib/`: `domain/`, `data/`, `presentation/`, `core/` (tema + breakpoints). Estado global com **Riverpod** (`ProviderScope` no `main`).
- [x] Tema base + limites de largura/texto para **PC e mobile** (`AppBreakpoints`, `AppTheme`). Tela placeholder até o fluxo real.

---

## Fase 2 — Modelo de dados no Firestore

- [ ] Definir coleções e documentos (exemplo base):
  - [x] `usuarios/{uid}` — `nome`, `role`: `admin` | `colab` (entidade Dart + `SETUP_USUARIOS.md`; `alunos` e `parcelas` na próxima etapa).
  - [ ] `alunos/{alunoId}` — `dados_pessoais` (**cadastro geral implementado**), `financeiro_contrato` (incluir `isLocked`) pendente, metadados `criadoEm`/`atualizadoEm`.
  - [ ] `alunos/{alunoId}/parcelas/{parcelaId}` — vencimento, pagamento, valores, status, forma de pagamento, atendente, etc.
- [ ] Documentar no código ou README interno os campos obrigatórios de cada documento.
- [ ] (Opcional) Coleção ou config para **feriados** (nacionais/regionais) usados no cálculo de atraso.

---

## Fase 3 — Autenticação e usuários fixos

- [ ] Criar no Firebase Auth os três usuários (Colaborador 1, Colaborador 2, Administrador) com as senhas definidas no escopo (passo manual no console — ver `app_escola/SETUP_USUARIOS.md`).
- [ ] Popular `usuarios/{uid}` com `role` correto (`admin` só para o administrador).
- [x] Tela de **login**: dropdown de usuário (mapeamento interno usuário → email) + campo senha com **obscureText**.
- [ ] Após login, carregar `role` e propagar permissões na UI (delete, unlock) — perfil já é lido; botões de permissão virão nas telas de cadastro.

---

## Fase 4 — Domínio: regras financeiras e calendário

- [x] Implementar função de **idade** a partir da data de nascimento (`lib/domain/calculo_idade.dart`; uso na guia Cadastro geral).
- [ ] Implementar **dias de atraso úteis**:
  - Sábado conta como dia normal.
  - Domingo **não** conta.
  - Feriados **não** contam (fonte: lista fixa, API ou cadastro admin — alinhar ao escopo).
  - Se o vencimento cair em domingo/feriado, considerar “em dia” pagamento no **próximo dia útil** (regra descrita no documento).
- [ ] Implementar **valor final da parcela**:  
  `mensalidade + (dias úteis de atraso × juros diário) − perda promocional` (ajustar conforme regra exata do contrato).
- [ ] Testes unitários das funções puras de cálculo (sem Firestore).

---

## Fase 5 — Telas principais (fluxo)

### 5.1 Cadastro geral

- [x] Máscaras: CPF, telefone; RG sem máscara fixa (varia por estado).
- [x] Campos: nome, telefone, CPF, RG, data nascimento, endereço, cidade, parentesco (select), dados do aluno + idade automática.
- [x] Botões: **Cadastrar novo aluno**, **Localizar** (filtro + lista ordenada por nome do aluno).
- [x] Ao salvar: persistir no Firestore e navegar para **Cadastro financeiro** (guia seguinte; conteúdo financeiro ainda placeholder).
- [ ] **Autosave** ao sair da guia/trocar de aba (debounce ou `WillPopScope`/`RouteObserver` conforme navegação escolhida).

### 5.2 Cadastro financeiro

- [ ] Preencher automaticamente nome do responsável e do aluno (somente leitura ou espelhados).
- [ ] Campos: data matrícula, pacote (com opção **Outros** editável), turmas (Tecnologia / Inglês), vencimento, duração (meses), valores e taxas, status (mensalista/bolsista + observação).
- [ ] Ao **primeiro save**: `isLocked = true` e bloquear edição dos campos.
- [ ] Ícone de **cadeado**: solicitar **senha do administrador** para desbloquear (somente `role == admin` pode confirmar desbloqueio, conforme regra).
- [ ] Botão **Localizar** com busca.
- [ ] Após salvar contrato: disparar **geração automática de parcelas** (quantidade = duração em meses).

### 5.3 Controle de parcelas

- [ ] Listar parcelas em tempo real (`snapshots()`).
- [ ] Por parcela: vencimento, data pagamento, valor pago, restante, datas, forma de pagamento, parcelamento crédito + taxa, atendente.
- [ ] Status automático e **cores**: verde (pago), amarelo (aberto), vermelho (atrasado), estados de bloqueio/alerta conforme especificação.
- [ ] Botão **salvar** por parcela (e garantir consistência — “salvar tudo” se for requisito único de UX).
- [ ] Recalcular juros/restante ao editar datas/valores respeitando as regras de dias úteis.

### 5.4 Relatórios (Sistema geral)

- [ ] **Alunos em débito**: nome aluno/responsável, parcelas em atraso, dias de atraso, valor atualizado, telefone, **exportar PDF**.
- [ ] **Aniversariantes do mês atual**: nome, data nascimento, turmas, **exportar PDF**.
- [ ] **(Somente admin) Alunos em dia**: filtro por mês, pagamentos sem atraso.
- [ ] **Alunos pagantes (geral)**: filtro por mês, todos os pagamentos (com ou sem atraso).

---

## Fase 6 — Segurança e permissões

- [ ] **Firestore Security Rules**: restringir `delete` em `alunos` apenas a claims/admin (ou regra baseada em `usuarios/{uid}.role`).
- [ ] Garantir que colaboradores **não** apagam alunos e **não** desbloqueiam sem fluxo admin (se a regra for só senha admin, validar no app + reforço nas rules se possível).
- [ ] Revisar leitura/escrita por coleção (`usuarios`, `alunos`, subcoleção `parcelas`).

---

## Fase 7 — UX polida e entrega

- [ ] Revisar responsividade (larguras grandes e pequenas).
- [ ] Tratamento de erros de rede e feedback (SnackBar/Dialog).
- [ ] Testar fluxo completo: login → cadastro → financeiro (lock) → parcelas → relatórios → PDF.
- [ ] Instruções de build: `flutter build web`, `flutter build apk` / `appbundle`, e notas para iOS.
- [ ] Entregar código versionado (Git) com `.env` ou arquivos sensíveis no `.gitignore` e documentação mínima de deploy Firebase.

---

## Observações finais

- A ordem das fases pode ser levemente ajustada (por exemplo, regras do Firestore cedo), mas **domínio (cálculos) testável** deve existir antes de amarrar tudo na UI.
- Se usar **Cloud Functions**, replique ou valide no servidor os cálculos mais críticos para evitar inconsistência por cliente alterando dados.

---

*Documento gerado para acompanhar o desenvolvimento do sistema descrito nas especificações funcionais e técnicas acordadas.*
