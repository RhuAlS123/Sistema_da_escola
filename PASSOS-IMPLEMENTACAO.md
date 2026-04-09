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
  - [x] `alunos/{alunoId}` — `dados_pessoais`, **`financeiro_contrato`** (`isLocked`, campos §5.2), metadados `criadoEm`/`atualizadoEm`.
  - [x] `alunos/{alunoId}/parcelas/{parcelaId}` — parcelas geradas (vencimento, valor, status); *campos extras* (pagamento, forma, atendente) pendentes.
- [x] Documentar no código ou README interno os campos obrigatórios de cada documento (`lib/data/firestore_model_doc.dart` + `SETUP_FIREBASE.md` §5).
- [ ] (Opcional) Coleção ou config para **feriados** (nacionais/regionais) usados no cálculo de atraso.

---

## Fase 3 — Autenticação e usuários fixos

- [ ] Criar no Firebase Auth os três usuários (Colaborador 1, Colaborador 2, Administrador) com as senhas definidas no escopo — **guia completo**: [`app_escola/SETUP_USUARIOS.md`](app_escola/SETUP_USUARIOS.md) (Console manual **ou** script em `app_escola/tools/seed_usuarios/`).
- [ ] Popular `usuarios/{uid}` com `role` correto (`admin` só para o administrador) — incluído no mesmo guia / script.
- [x] Tela de **login**: dropdown de usuário (mapeamento interno usuário → email) + campo senha com **obscureText**.
- [x] Após login, carregar `role` e propagar permissões na UI (delete aluno, desbloqueio financeiro com senha admin).

---

## Fase 4 — Domínio: regras financeiras e calendário

- [x] Implementar função de **idade** a partir da data de nascimento (`lib/domain/calculo_idade.dart`; uso na guia Cadastro geral).
- [x] Implementar **dias de atraso úteis**:
  - Sábado conta como dia normal.
  - Domingo **não** conta.
  - Feriados **não** contam (fonte: lista fixa nacional em `feriados_brasil.dart`; extensível via `feriadosExtras` no futuro).
  - Se o vencimento cair em domingo/feriado, considerar “em dia” pagamento no **próximo dia útil** (`vencimentoCobrancaEfetivo`).
- [x] Implementar **valor final da parcela**:  
  `mensalidade + (dias úteis de atraso × juros diário) − perda promocional` (`valor_parcela_juros.dart`; `juros_diario` no contrato).
- [x] Testes unitários das funções puras de cálculo (sem Firestore) — `test/calculo_financeiro_fase4_test.dart`.

---

## Fase 5 — Telas principais (fluxo)

### 5.1 Cadastro geral

- [x] Máscaras: CPF, telefone; RG sem máscara fixa (varia por estado).
- [x] Campos: nome, telefone, CPF, RG, data nascimento, endereço, cidade, parentesco (select), dados do aluno + idade automática.
- [x] Botões: **Cadastrar novo aluno**, **Localizar** (filtro + lista ordenada por nome do aluno).
- [x] Ao salvar: persistir no Firestore e navegar para **Cadastro financeiro** (guia seguinte; conteúdo financeiro ainda placeholder).
- [x] **Autosave** ao sair da guia/trocar de aba (`ref.listen` em `mainTabIndexProvider` + flag `_dirty`; sem debounce inicial).

### 5.2 Cadastro financeiro

- [x] Preencher automaticamente nome do responsável e do aluno (somente leitura ou espelhados).
- [x] Campos: data matrícula, pacote (com opção **Outros** editável), turmas (Tecnologia / Inglês), vencimento, duração (meses), valores e taxas, status (mensalista/bolsista + observação).
- [x] Ao **primeiro save**: `isLocked = true` e bloquear edição dos campos.
- [x] Ícone de **cadeado** + solicitar **senha do administrador** para desbloquear (somente `role == admin`).
- [x] Botão **Localizar** com busca.
- [x] Após salvar contrato: **geração automática de parcelas** (quantidade = duração em meses).

### 5.3 Controle de parcelas

- [x] Listar parcelas em tempo real (`snapshots()` na subcoleção `parcelas`).
- [x] Por parcela: vencimento, data pagamento, valor pago, restante, forma de pagamento, parcelamento crédito + taxa, atendente.
- [x] Status automático e **cores**: verde (pago), amarelo (aberto), vermelho (atrasado).
- [x] Botão **salvar** por parcela.
- [x] Recalcular **juros** e valor final ao editar datas/valores (**Fase 4** — exibição em tempo real na guia parcelas + relatório débito).

### 5.4 Relatórios (Sistema geral)

- [x] **Alunos em débito**: nome aluno/responsável, parcelas em atraso, dias de atraso, valor atualizado, telefone, **exportar PDF**.
- [x] **Aniversariantes do mês atual**: nome, data nascimento, turmas, **exportar PDF**.
- [x] **(Somente admin) Alunos em dia**: filtro por mês, pagamentos sem atraso (regra no código + PDF).
- [x] **Alunos pagantes (geral)**: filtro por mês, todos os pagamentos (com ou sem atraso) + PDF.

---

## Fase 6 — Segurança e permissões

- [x] **Firestore Security Rules**: `delete` em `alunos/{id}` só com `usuarios/{uid}.role == 'admin'` e documento existente; `parcelas` com delete permitido a qualquer utilizador autenticado (recalcular contrato).
- [x] Colaboradores **não** apagam documento de aluno nas rules; desbloqueio financeiro continua só no app com senha admin (`role == admin`).
- [x] Leitura/escrita revisada: `usuarios` leitura própria; `alunos` + `parcelas` CRUD operacional; `firebase.json` aponta para `firestore.rules`.
- [x] **Publicar regras no Firebase**: `firebase deploy --only firestore:rules` (projeto predefinido em `app_escola/.firebaserc` — `app-escola-fda78`; ver `SETUP_FIREBASE.md`).

---

## Fase 7 — UX polida e entrega

- [x] Revisar responsividade (larguras grandes e pequenas) — shell usa `AppBreakpoints.isMobileWidth` para rail vs barra; texto limitado por `App` (`minTextScale` / `maxTextScale`).
- [x] Tratamento de erros de rede e feedback (SnackBar/Dialog) — `lib/core/errors/app_error_messages.dart` + SnackBars nas telas com gravação Firestore/Auth.
- [ ] Testar fluxo completo: login → cadastro → financeiro (lock) → exclusão admin (opcional) → parcelas → relatórios → PDF *(checklist em `app_escola/README.md` — validar na máquina)*.
- [x] Instruções de build: `flutter build web`, `flutter build apk` / `appbundle`, e notas para iOS — `app_escola/README.md`.
- [x] Git + sensíveis: `.gitignore` com `.env`/`.env.*`; deploy Firebase referenciado em `README` e `SETUP_FIREBASE.md` §5.

---

## Observações finais

- A ordem das fases pode ser levemente ajustada (por exemplo, regras do Firestore cedo), mas **domínio (cálculos) testável** deve existir antes de amarrar tudo na UI.
- Se usar **Cloud Functions**, replique ou valide no servidor os cálculos mais críticos para evitar inconsistência por cliente alterando dados.

---

*Documento gerado para acompanhar o desenvolvimento do sistema descrito nas especificações funcionais e técnicas acordadas.*
