# Utilizadores fixos — Firebase Auth + Firestore `usuarios/{uid}`

O login usa **e-mail/senha** com contas fixas. Os e-mails **têm de coincidir** com [`lib/core/auth/fixed_auth_mapping.dart`](lib/core/auth/fixed_auth_mapping.dart).

| Conta no app        | E-mail (Auth)       | `role` em Firestore |
|---------------------|---------------------|---------------------|
| Colaborador 1       | `colab1@escola.com` | `colab`             |
| Colaborador 2       | `colab2@escola.com` | `colab`             |
| Administrador       | `admin@escola.com`  | `admin`             |

**Senhas:** defina-as com o cliente (documento de escopo) e use **as mesmas** ao criar no Firebase Authentication. **Não** as coloque em ficheiros versionados.

---

## Pré-requisitos no Firebase Console

1. Projeto criado (ex.: `app-escola-fda78` — alinhar com `lib/firebase_options.dart` e [`.firebaserc`](.firebaserc)).
2. **Authentication** → Sign-in method → **E-mail/senha** → ativar.
3. **Firestore** criado (modo produção ou teste; depois alinhar [regras](firestore.rules)).

---

## Opção A — Tudo manual (Console)

### 1) Criar os 3 utilizadores em Authentication

1. Firebase Console → **Authentication** → **Users** → **Add user**.
2. Para cada linha da tabela acima: e-mail + senha (a que combinou com o cliente).
3. Anote o **UID** de cada um (coluna na lista de utilizadores).

### 2) Criar documentos `usuarios/{uid}`

1. **Firestore** → **Data** → coleção `usuarios` (criar se não existir).
2. Para cada UID do passo anterior, crie um documento com **ID = UID** (não um ID aleatório).
3. Campos (tipo string):

| Campo   | Colaborador 1 | Colaborador 2 | Administrador |
|---------|---------------|---------------|---------------|
| `nome`  | `Colaborador 1` | `Colaborador 2` | `Administrador` |
| `role`  | `colab`       | `colab`       | `admin`       |

4. Guarde. Sem estes documentos, o app pode não reconhecer o `role` (ex.: exclusão de aluno, desbloqueio).

---

## Opção B — Script (recomendado para repetir / novos ambientes)

Cria automaticamente os utilizadores em **Auth** (se ainda não existirem) e os documentos em **`usuarios/{uid}`**.

Requisitos: [Node.js](https://nodejs.org/) 18+ e uma **chave de conta de serviço** (não versionar):

1. Firebase Console → **Project settings** → **Service accounts** → **Generate new private key** → guarde como ficheiro JSON (ex.: `serviceAccount.json`) **fora** do Git.
2. Na pasta [`tools/seed_usuarios`](tools/seed_usuarios):

   ```powershell
   cd app_escola\tools\seed_usuarios
   npm install
   (Gera `package-lock.json` localmente; não é obrigatório versionar.)
   ```

3. Defina as **mesmas** senhas que vai usar no app (apenas no terminal, não em ficheiros no repositório):

   ```powershell
   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\caminho\para\serviceAccount.json"
   $env:SEED_PASS_COLAB1="senha-do-colab1"
   $env:SEED_PASS_COLAB2="senha-do-colab2"
   $env:SEED_PASS_ADMIN="senha-do-admin"
   node seed.mjs
   ```

   Ou numa linha (PowerShell):

   ```powershell
   $env:GOOGLE_APPLICATION_CREDENTIALS="..."; $env:SEED_PASS_COLAB1="..."; $env:SEED_PASS_COLAB2="..."; $env:SEED_PASS_ADMIN="..."; node seed.mjs
   ```

4. Confirme em **Authentication** e **Firestore** que os 3 utilizadores e os 3 documentos existem.

**Segurança:** apague ou guarde a chave só em local seguro; não faça commit do JSON (o repositório ignora padrões como `**/firebase-adminsdk-*.json` — ver `.gitignore` na raiz).

---

## Publicar regras do Firestore

Depois de qualquer alteração a [`firestore.rules`](firestore.rules), publique no mesmo projeto do app:

```powershell
cd app_escola
firebase deploy --only firestore:rules
```

(Ver também [SETUP_FIREBASE.md](SETUP_FIREBASE.md) §5 — login Firebase CLI, projeto, PowerShell no Windows.)

---

## Verificação rápida

1. Abrir o app → login como **Administrador** com `admin@escola.com` e a senha definida.
2. Deve carregar o perfil sem avisos de `usuarios` em falta; em **Financeiro**, como admin, deve aparecer **Excluir aluno** (e fluxo de desbloqueio conforme regras).
