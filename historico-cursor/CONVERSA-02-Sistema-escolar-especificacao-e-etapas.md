# Conversa 2 — Sistema escolar (escopo, PASSOS e Firebase)

Este arquivo foi gerado a partir do histórico salvo pelo Cursor (`agent-transcripts`). Referências a imagens aparecem como texto; os arquivos de imagem podem estar na pasta de assets do projeto no Cursor.

---

### Você

Sistema de cadastro de alunos (Web + Mobile)

Preciso de um sistema completo de cadastro de alunos com acesso multiusuário, funcionando em PC, Android e iOS, com atualização em tempo real.

Login do sistema

Usuários pré-definidos:

- Colaborador 1 (senha: 12342020)
- Colaborador 2 (senha: 12343030)
- Administrador (senha: adm102030)

- Senhas ocultas com asterisco
- Seleção de usuário no login

Estrutura do sistema (Guias)

1. Cadastro Geral
Cadastro completo do responsável e do aluno.
Campos:
- Nome
- Telefone
- CPF (com máscara)
- RG
- Data de nascimento
- Endereço
- Cidade
- Parentesco (select)
- Dados do aluno e cálculo automático da idade

Botões:
- Cadastrar novo aluno
- Localizar aluno (busca com filtro e lista alfabética)

Ao salvar, ir para Cadastro Financeiro.

2. Cadastro Financeiro
Campos:
- Nome do responsável e do aluno (automático)
- Data de matrícula
- Pacote de cursos (opção 'Outros' editável)
- Turmas (Tecnologia / Inglês)
- Vencimento
- Duração (meses)
- Valores: mensalidade, perda promocional, juros diário
- Taxas: contrato, reteste, multa
- Status (Mensalista / Bolsista com observação)

Regras:
- Após salvar, bloquear edição
- Somente administrador pode desbloquear (senha)
- Botão localizar com busca

3. Controle de Parcelas
Geração automática das parcelas com base na duração.

Regras:
- Cálculo automático de juros e perda promocional
- Não considerar atraso em domingos/feriados
- Sábado conta como dia normal

Campos por parcela:
- Data de vencimento
- Data de pagamento
- Valor pago
- Restante
- Data restante de pagamento
- Forma de pagamento (dinheiro, pix, crédito, etc.)
- Parcelamento no crédito (com taxa)
- Atendente

Status automático:
- Pagamento em dia
- Pago em atraso
- Em aberto
- Bloqueio após quitação
- Alertas de atraso
- Cores diferentes por parcela

- Botão salvar por parcela (salva tudo automaticamente)

4. Sistema Geral (Relatórios)

- Alunos em débito
Mostrar:
- Nome do aluno / responsável
- Parcelas em atraso
- Dias de atraso
- Valor atualizado
- Telefone
- Botão exportar PDF

- Alunos aniversariantes
Listar por mês atual
Mostrar:
- Nome
- Data de nascimento
- Turmas
- Exportar PDF

- (Administrador) Alunos em dia
Filtrar por mês
Mostrar pagamentos sem atraso

- Alunos pagantes (geral)
Filtrar por mês
Mostrar todos os pagamentos (com ou sem atraso)

Segurança
- Campos bloqueados após salvar
- Desbloqueio apenas com senha do administrador
- Ícone de cadeado para liberar edição

Requisitos técnicos
- Sistema responsivo (PC + mobile)
- Banco de dados em tempo real (ex: Firebase)
- Interface simples e organizada
- Salvamento automático ao trocar de tela

Objetivo

Sistema completo para gestão de alunos, financeiro e controle de pagamentos com regras automatizadas.

Permissões administrativas

- Ao entrar no sistema como administrador, posso excluir alunos; somente o administrador tem essa permissão.

Entrega

- O sistema deve ser entregue pronto, funcionando e com acesso aos arquivos/código para que eu possa fazer modificações futuras. eu tenho que fazer esse projeto quero que voce leia mas ainda nao faz nehum codigo por favor

### Assistente

Li o escopo completo. Resumo objetivo do que você pediu, **sem escrever código**.

## Visão geral
Sistema de **cadastro de alunos** com **login multiusuário**, **interface responsiva** (PC, Android, iOS), **dados em tempo real** (você citou exemplo **Firebase**) e **salvamento automático** ao mudar de tela/guia.

## Login
- Usuários fixos: **Colaborador 1**, **Colaborador 2**, **Administrador** (com as senhas indicadas).
- **Seleção de usuário** no login (não digitar usuário livre).
- **Senha mascarada** (asteriscos).

## Estrutura em guias

### 1. Cadastro geral
Dados do **responsável** e do **aluno** (nome, telefone, CPF com máscara, RG, nascimento, endereço, cidade, parentesco em select, dados do aluno + **idade automática**).
- Ações: **Cadastrar novo aluno**, **Localizar** (filtro + lista alfabética).
- Ao **salvar** → seguir para **Cadastro financeiro**.

### 2. Cadastro financeiro
Campos de matrícula, pacote (com **“Outros”** editável), turmas (Tecnologia / Inglês), vencimento, duração, valores (mensalidade, perda promocional, juros diário), taxas, status (mensalista / bolsista com observação).
- **Após salvar**: **bloquear edição**; só **admin** desbloqueia com **senha**; botão **localizar** com busca.

### 3. Controle de parcelas
**Geração automática** conforme duração; regras de **juros** e **perda promocional**; **domingo e feriado não contam** como atraso; **sábado conta**.
- Por parcela: vencimento, pagamento, valor pago, restante, datas, forma de pagamento, parcelamento no crédito com taxa, atendente.
- Status/cores automáticos (em dia, atrasado, aberto, bloqueio após quitação, alertas).
- **Salvar por parcela** (e conceito de “salvar tudo”).

### 4. Sistema geral (relatórios)
- **Alunos em débito** (lista + PDF): nome/aluno-responsável, parcelas atrasadas, dias de atraso, valor atualizado, telefone.
- **Aniversariantes do mês** (lista + PDF): nome, nascimento, turmas.
- **(Só admin) Alunos em dia**: filtro por mês, pagamentos **sem** atraso.
- **Alunos pagantes (geral)**: filtro por mês, **todos** os pagamentos (com ou sem atraso).

## Segurança e permissões
- **Bloqueio pós-salvar** + **ícone de cadeado** e **desbloqueio só com senha do administrador**.
- **Exclusão de alunos**: **somente administrador**.

## Entrega
Projeto **funcionando**, com **código/arquivos** para você evoluir depois.

---

Quando quiser começar a implementação, diga **stack preferida** (ex.: React + Capacitor, Flutter, etc.) e se você **já tem conta/projeto Firebase**; aí partimos do zero no código com isso alinhado. Por ora, como pediu, **não farei nenhuma alteração nem código no repositório**.

---

### Você

# Especificação Técnica: Sistema de Gestão Escolar (SaaS)

## 1. Visão Geral
Sistema multiusuário (Web + Mobile) para cadastro de alunos e controle financeiro em tempo real. O foco principal é o rigor no controle de parcelas, cálculos de juros e restrição de acesso administrativo.

## 2. Stack Tecnológica (Recomendada)
- **Frontend:** Flutter (para cobertura Web, Android e iOS com código único).
- **Backend/DB:** Firebase (Firestore para Real-time e Auth para autenticação).
- **Lógica de Servidor:** Firebase Cloud Functions (opcional, para cálculos críticos).

## 3. Modelo de Dados (Firestore)
- `/usuarios/{uid}`: {nome, role: 'admin' | 'colab'}
- `/alunos/{alunoId}`:
    - `dados_pessoais`: {nome, cpf, data_nasc, endereco, etc.}
    - `financeiro_contrato`: {pacote, valor_mensal, duracao, isLocked: bool}
    - `subcolecao_parcelas`: Documentos por mês {vencimento, status, valor_pago, forma_pagamento}

## 4. Regras de Negócio e Lógica Financeira

### A. Autenticação e Permissões
- **Usuários Fixos:**
    - Colaborador 1 / 12342020
    - Colaborador 2 / 12343030
    - Administrador / adm102030 (Único com permissão de DELETE e UNLOCK).
- **Bloqueio de Edição:** Após salvar o Cadastro Financeiro, o campo `isLocked` deve ser setado como `true`. Apenas a senha do Admin libera os campos novamente.

### B. Cálculo de Juros e Atrasos
- **Regra de Dias Úteis:** - Sábados contam como dia normal.
    - Domingos e Feriados **NÃO** geram atraso. Se o vencimento cair nesses dias, o pagamento no próximo dia útil é considerado "Em dia".
- **Fórmula:** `Valor Final = Mensalidade + (Dias de Atraso Úteis * Juros Diário) - Perda Promocional (se houver)`.

### C. Automação
- **Geração de Parcelas:** Ao salvar o contrato financeiro (ex: 12 meses), o sistema deve iterar e criar automaticamente os 12 registros de parcelas no banco de dados.
- **Salvamento:** Implementar autosave ao trocar de guias (Cadastro -> Financeiro -> Parcelas).

## 5. Estrutura de Telas e Requisitos de UI
1. **Login:** Seleção de usuário (dropdown) + Input de senha (obscureText).
2. **Cadastro Geral:** Máscaras de CPF, RG e Telefone. Cálculo automático de idade baseado na Data de Nascimento.
3. **Financeiro:** Bloqueio de campos com ícone de cadeado.
4. **Controle de Parcelas:** - Cores dinâmicas (Verde: Pago, Vermelho: Atrasado, Amarelo: Aberto).
    - Opções de pagamento: Dinheiro, Pix, Crédito (com campo para taxa).
5. **Relatórios:** Filtros por mês e exportação para PDF.

## 6. Prompt para o Cursor (Sugestão)
> "Atue como um Engenheiro de Software Sênior. Utilize Flutter e Firebase para criar o sistema descrito neste documento. Siga o padrão Clean Architecture. Comece estruturando a camada de domínio (entidades e regras de cálculo de juros) e a integração com o Firestore para garantir o tempo real." le esse agora por favor

### Assistente

Li a especificação técnica. Segue um resumo fiel do que ela define, **sem implementar nada**.

## Visão geral
Sistema **multiusuário** (Web + Android + iOS) com **cadastro + financeiro em tempo real**, ênfase em **parcelas**, **juros** e **permissões** (admin vs colaborador).

## Stack recomendada
- **Flutter** (código único para web e mobile).
- **Firebase**: **Firestore** (dados em tempo real) + **Auth** (autenticação).
- **Cloud Functions** opcional para lógica crítica no servidor.

## Modelo Firestore (esboço)
- `usuarios/{uid}` → `nome`, `role`: `admin` | `colab`.
- `alunos/{alunoId}` com:
  - `dados_pessoais` (nome, CPF, data nasc., endereço, etc.).
  - `financeiro_contrato` (pacote, valor mensal, duração, **`isLocked`**).
  - Subcoleção **`parcelas`** (documentos por mês: vencimento, status, valor pago, forma de pagamento, etc.).

## Regras principais
- **Usuários fixos** com as mesmas credenciais que você já definiu; **só admin** com **DELETE** e **UNLOCK**.
- **Cadastro financeiro**: ao salvar, **`isLocked: true`**; só **senha do admin** libera edição de novo.
- **Atraso**: **sábado conta**; **domingo e feriados não geram atraso**; se vencimento cair nesses dias, pagar no **próximo dia útil** pode contar como **em dia**.
- **Valor final** (conceito): mensalidade + (dias úteis de atraso × juros diário) − perda promocional (se houver).
- **Parcelas**: ao salvar contrato (ex.: 12 meses), **gerar automaticamente** os registros de parcelas.
- **Autosave** ao **trocar de guias** (Cadastro → Financeiro → Parcelas).

## UI (telas)
- Login: **dropdown de usuário** + senha **obscure**.
- Cadastro geral: máscaras **CPF, RG, telefone**; **idade** automática pela data de nascimento.
- Financeiro: campos bloqueados + **ícone de cadeado**.
- Parcelas: cores (verde pago, vermelho atrasado, amarelo aberto); formas de pagamento incluindo **crédito com taxa**.
- Relatórios: filtros por mês + **exportar PDF**.

## Sugestão de abordagem no Cursor
Começar por **Clean Architecture**: camada de **domínio** (entidades + regras de juros/atraso) e depois integração **Firestore** para tempo real.

---

Está alinhado com o documento anterior; esta versão só **formaliza stack**, **estrutura de coleções** e **pontos de automação/bloqueio**. Quando quiser que eu **abra o projeto na pasta do workspace e comece a estruturar o Flutter + Firebase**, é só dizer.

---

### Você

gere um arquivo .md do passo do que deve ser feito

### Assistente

Criando um arquivo Markdown com o plano de implementação passo a passo, alinhado às especificações que você definiu.


*(Glob)*

---

### Assistente

*(Write)*

---

### Assistente

Criei o arquivo **`PASSOS-IMPLEMENTACAO.md`** na raiz do projeto:

`c:\Users\AMTK-Estágio\Desktop\Projetos Pessoais\Freela\Sistema da escola\PASSOS-IMPLEMENTACAO.md`

Ele organiza o trabalho em **fases** (ambiente → Flutter/arquitetura → Firestore → auth → domínio financeiro → telas → relatórios/PDF → segurança → entrega), com **checklists** `[ ]` para você ir marcando. Se quiser, no próximo passo podemos alinhar o arquivo ao que já existe na pasta `app_escola` (dependências e estrutura atual).

---

### Você

Com base nesse arquivo que você gerou comceça o prjeto mas faz etapa por etapa me explicando e o mais importante nunca invente nada sem saber

### Assistente

Iniciando pelo que o documento define como Fase 0 e início da Fase 1: inspecionando o projeto existente e validando o ambiente. Não inventaremos regras não especificadas — onde faltar definição, deixaremos explícito e usaremos o mínimo necessário.


*(Read)*




*(Read)*




*(Read)*

---

### Assistente

Validando o ambiente e, em seguida, aplicando a Etapa 1 do plano: dependências e esqueleto da arquitetura. Não vamos inventar IDs do Firebase nem credenciais — o app só inicializará o Firebase depois que você rodar `flutterfire configure` (documentado).


*(Shell — Validate Flutter SDK and toolchain (flutter doctor))*

---

### Assistente

*(Shell — Run flutter doctor in app_escola (PowerShell))*

---

### Assistente

*(Shell — Locate dart/flutter executables on PATH)*

---

### Assistente

Flutter não está no PATH neste ambiente — não conseguimos rodar `flutter doctor` daqui. Continuando: adicionando dependências e o esqueleto do projeto; você valida `flutter doctor` e `flutter pub get` na sua máquina.


*(Read)*

---

### Assistente

*(Read)*

---

### Assistente

Implementando a Etapa 1: dependências no `pubspec.yaml`, pastas da arquitetura, tema básico, `ProviderScope` (escolha explícita: o `PASSOS-IMPLEMENTACAO.md` lista Provider, Riverpod ou Bloc — usamos Riverpod por ser comum e escalável). Não inicializamos o Firebase no `main` porque exige `firebase_options.dart` gerado pelo seu projeto no Firebase (sem inventar IDs).


*(StrReplace)*




*(StrReplace)*




*(Write)*




*(Write)*




*(Write)*




*(Write)*




*(Write)*




*(Write)*




*(Write)*




*(Write)*

---

### Assistente

*(StrReplace)*




*(ReadLints)*

---

### Assistente

*(StrReplace)*




*(StrReplace)*

---

### Assistente

*(ReadLints)*

---

### Assistente

*(Shell — Check if Flutter/Dart appears in PATH)*

---

### Assistente

Segue o que foi feito **nesta primeira etapa**, o que **depende de você** (sem inventar dados externos) e o que vem **em seguida**.

---

## O que esta etapa cobre (Fase 1 do `PASSOS-IMPLEMENTACAO.md`)

1. **`pubspec.yaml`**  
   Além do `firebase_core` que já existia, foram declaradas as dependências alinhadas ao plano: `cloud_firestore`, `firebase_auth`, `flutter_riverpod`, `intl`, `mask_text_input_formatter`, `pdf`, `printing`.  
   **Escolha explícita:** **Riverpod** — o documento permite Provider, Riverpod ou Bloc; Riverpod combina bem com camadas `domain` / `data` / `presentation`.

2. **Estrutura de pastas (Clean Architecture, só o esqueleto)**  
   - `lib/domain/domain.dart` — camada de domínio (regras e entidades virão nas próximas etapas).  
   - `lib/data/data.dart` — camada de dados (Firestore depois).  
   - `lib/core/` — tema e breakpoints responsivos.  
   - `lib/presentation/home/home_placeholder_page.dart` — tela temporária até login/abas.

3. **`main.dart`**  
   `WidgetsFlutterBinding.ensureInitialized()` + `ProviderScope` + `AppEscola`.  
   **Não** há `Firebase.initializeApp()` ainda: isso exige o arquivo **`firebase_options.dart`** do **seu** projeto no Firebase. Inventar projeto/IDs quebraria o princípio de “não inventar nada sem saber”.

4. **`SETUP_FIREBASE.md`** (dentro de `app_escola/`)  
   Passos oficiais: console Firebase → `flutterfire configure` → depois colocar `Firebase.initializeApp(...)` no `main`. Nada disso pode ser adivinhado daqui.

5. **`PASSOS-IMPLEMENTACAO.md`**  
   Itens da Fase 1 relacionados a dependências, pastas e tema foram marcados como feitos; o item “abrir no Chrome/Android” continua para você validar localmente.

6. **Teste**  
   `test/widget_test.dart` atualizado para o app novo (procura o texto “Etapa 1”).

---

## O que você precisa fazer na sua máquina agora

1. Abrir o terminal na pasta `app_escola` e rodar **`flutter pub get`**.  
   Aqui o comando **`flutter` não está no PATH`**, então não consegui validar a resolução de pacotes neste ambiente — se aparecer conflito de versões, envie a mensagem de erro.

2. Rodar **`flutter doctor`** e, se possível, **`flutter run -d chrome`** (e um emulador Android) para fechar o item da Fase 1 “garantir que o app abre”.

---

## Próxima etapa lógica (quando você disser “seguir”)

- **Fase 0 (Firebase):** criar projeto no console, ativar Auth + Firestore, rodar `flutterfire configure`, depois **eu** adiciono no código o `Firebase.initializeApp` com o `firebase_options.dart` gerado.  
- **Fase 2:** modelar campos dos documentos `usuarios`, `alunos`, `parcelas` **exatamente** como no seu documento (sem supor campos a mais).

Se quiser, na próxima mensagem diga só **“seguir para Firebase”** (depois que tiver o projeto criado) ou **“seguir modelo Firestore sem Firebase ainda”** (só estruturas Dart + interfaces), que eu continuo **uma etapa por vez** e paro onde faltar dado seu.

---

### Você

seguir para firebase

### Assistente

Verificando se o FlutterFire já gerou `firebase_options.dart` e, em seguida, ligando o Firebase no `main`.


*(Glob)*




*(Read)*




*(Read)*

---

### Assistente

Não há `firebase_options.dart` no projeto — precisamos gerá-lo com o FlutterFire CLI (credenciais do seu projeto). Tentando executar o comando no ambiente; se falhar, deixaremos o código pronto e instruções claras.


*(Shell — Check if flutter/dart commands are available)*

---

### Assistente

Flutter não está disponível neste ambiente para rodar `flutterfire configure`. Implementando inicialização do Firebase no `main` e um `firebase_options.dart` temporário que indica claramente que deve ser substituído pelo arquivo gerado pelo FlutterFire (sem inventar credenciais). Verificando a configuração Android para o Firebase.


*(Read)*




*(Read)*




*(Read)*

---

### Assistente

Ligando o Firebase no código, adicionando o plugin Android necessário para `google-services.json` e um `firebase_options.dart` provisório que instrui a substituição pelo arquivo gerado pelo FlutterFire (sem credenciais inventadas).


*(Write)*




*(Write)*




*(StrReplace)*




*(StrReplace)*

---

### Assistente

Corrigindo erro de digitação no plugin Flutter.


*(StrReplace)*

---

### Assistente

Removendo o plugin `google-services` que adicionamos: sem `google-services.json` o build Android costuma falhar. O `flutterfire configure` costuma aplicar plugin e arquivo juntos.


*(StrReplace)*




*(StrReplace)*

---

### Assistente

Refatorando: extrair a inicialização para `lib/core/firebase/app_firebase.dart` e remover o `ValueNotifier` (evita acoplar UI ao `main`).


*(Write)*




*(Write)*




*(StrReplace)*




*(StrReplace)*

---

### Assistente

*(Write)*




*(StrReplace)*

---

### Assistente

*(Read)*

---

### Assistente

*(StrReplace)*

---

### Assistente

*(StrReplace)*




*(ReadLints)*

---

### Assistente

Segue o que foi feito nesta etapa **Firebase** e o que **só você pode fazer** na sua máquina (credenciais reais).

---

## O que o código faz agora

1. **`lib/core/firebase/app_firebase.dart`**  
   Chama `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` e define a flag global **`appFirebaseInitialized`** (`true` só quando o init termina sem erro).

2. **`lib/firebase_options.dart` (stub)**  
   Não contém API keys inventadas. O getter `currentPlatform` lança **`UnsupportedError`** com instruções até você rodar o FlutterFire. Esse erro é tratado em `initializeAppFirebase()`; o app **continua abrindo** sem Firebase.

3. **`lib/main.dart`**  
   `await initializeAppFirebase()` antes do `runApp`.

4. **`HomePlaceholderPage`**  
   Texto muda conforme `appFirebaseInitialized` (sucesso vs ainda sem credenciais).

5. **`SETUP_FIREBASE.md`**  
   Atualizado com o fluxo: console → `flutterfire configure` → conferência.

6. **`PASSOS-IMPLEMENTACAO.md`**  
   Item marcado para o código de inicialização + stub.

7. **Android**  
   Não foi adicionado o plugin `google-services` manualmente: **sem `google-services.json` o build costuma quebrar**. O `flutterfire configure` costuma aplicar plugin + JSON juntos; deixamos isso para o assistente.

---

## O que você precisa executar (na pasta `app_escola`)

1. Projeto no **Firebase Console** + apps Web/Android/iOS + **Authentication (e-mail/senha)** + **Firestore**.

2. No terminal:

```bash
dart pub global activate flutterfire_cli
flutter pub get
flutterfire configure
```

3. Isso **substitui** `lib/firebase_options.dart` pelo arquivo gerado (com suas credenciais) e ajusta os projetos nativos.

4. Rodar o app de novo: a tela deve mostrar que o Firebase subiu e, em debug, algo como `[Firebase] OK`.

---

## Por que não “geramos” o `firebase_options.dart` daqui

Ele depende do **seu** `projectId`, `appId`, chaves da API etc. Inventar isso quebraria o princípio de não assumir dados que não temos; o stub deixa o projeto **compilável** até você rodar o `flutterfire configure`.

Quando tiver rodado o `flutterfire configure` e o app mostrar Firebase OK, o próximo passo lógico é **Fase 2 + 3**: modelo Firestore (`usuarios`, `alunos`, `parcelas`) e **login** com os três usuários fixos. Quer seguir por **modelo de dados** ou por **tela de login** primeiro?

---

### Você

*(sem texto)*

### Assistente

O que aparece na tela está **correto** para o estágio atual: o app está rodando na web, mas o **`firebase_options.dart` ainda é o stub** (ou o `flutterfire configure` ainda não foi aplicado / falhou), então a mensagem pede credenciais reais.

**Próximos passos (na pasta `app_escola`):**

1. No [Firebase Console](https://console.firebase.google.com/), tenha um projeto com app **Web** (e os demais quando for buildar Android/iOS).
2. No terminal (PowerShell), na pasta do projeto:

```powershell
dart pub global activate flutterfire_cli
flutter pub get
flutterfire configure
```

3. Escolha o projeto Firebase e marque **Web** (e Android/iOS se já cadastrou).
4. Confirme que o arquivo **`lib/firebase_options.dart`** foi **substituído** pelo gerado (não deve mais ter só o `UnsupportedError`).
5. Pare o `flutter run` e suba de novo (`flutter run -d chrome`).

Quando der certo, o texto central deve mudar para algo como **Firebase inicializado com sucesso** e no console de debug deve aparecer **`[Firebase] OK`**.

Se o `flutterfire configure` mostrar erro (login, projeto não listado, etc.), copie a mensagem do terminal e envie aqui que ajustamos o passo a passo.

---

