# Firebase — configurar o projeto (obrigatório para Auth + Firestore)

O app já chama `Firebase.initializeApp` em [`lib/core/firebase/app_firebase.dart`](lib/core/firebase/app_firebase.dart). Falta **o seu** projeto no Firebase e o arquivo **`lib/firebase_options.dart`** com credenciais reais.

Enquanto isso, o repositório contém um **`firebase_options.dart` stub** que lança `UnsupportedError`: o app **abre normalmente**, mas `appFirebaseInitialized` fica `false` até você gerar o arquivo correto.

---

## 1. Console Firebase

1. Abra [Firebase Console](https://console.firebase.google.com/) e crie um projeto (ou use um existente).
2. Registre os apps **Web**, **Android** e **iOS** no mesmo projeto (para build em cada plataforma).
3. Ative **Authentication** → método **E-mail/senha** (para os três usuários fixos do escopo).
4. Cadastre os três usuários e os documentos `usuarios/{uid}` conforme **`SETUP_USUARIOS.md`** (e-mails técnicos + campos `nome` e `role`).
5. Ative **Cloud Firestore** (comece em modo de teste; depois ajuste regras de segurança).

---

## 2. FlutterFire CLI (gera `firebase_options.dart` e ajusta nativos)

No terminal, na pasta **`app_escola`**:

```bash
dart pub global activate flutterfire_cli
flutter pub get
flutterfire configure
```

- Escolha o projeto Firebase e **todas** as plataformas que for usar.
- O comando **substitui** `lib/firebase_options.dart` pelo arquivo gerado (com `DefaultFirebaseOptions` completo).
- Em geral também cria/atualiza **`android/app/google-services.json`**, **`ios/Runner/GoogleService-Info.plist`** e pode adicionar o plugin **Google Services** no Gradle — **aceite essas alterações**.

Se o Android reclamar de `google-services.json` ausente, rode o `flutterfire configure` de novo após registrar o app Android no console.

---

## 3. Conferir

1. `flutter run` (Chrome ou Android).
2. Na tela inicial, a mensagem deve indicar **Firebase inicializado com sucesso** quando `initializeAppFirebase` funcionar.
3. No console de debug, procure `[Firebase] OK`.

---

## 4. Web (se usar)

O FlutterFire costuma configurar opções Web no `firebase_options.dart`. Se algo falhar só no Chrome, confira no console do Firebase se o app **Web** está registrado e se as chaves batem com o arquivo gerado.

---

## 5. Regras de segurança (Firestore)

O arquivo [`firestore.rules`](firestore.rules) no repositório define:

- Utilizador autenticado pode ler/criar/atualizar `alunos` e `alunos/{id}/parcelas` (incluindo **delete** em parcelas ao recalcular o contrato).
- Apenas `role == admin` em `usuarios/{uid}` pode **apagar** o documento `alunos/{id}`.
- `usuarios/{uid}` só leitura pelo próprio utilizador; escrita desativada (seed pelo console ou script).

Para publicar no projeto (com [Firebase CLI](https://firebase.google.com/docs/cli) logado):

```bash
cd app_escola
firebase deploy --only firestore:rules
```

O ficheiro [`.firebaserc`](.firebaserc) define o projeto predefinido `app-escola-fda78` (o mesmo que em `firebase_options.dart`). Se ainda aparecer *«No currently active project»*, corre `firebase login` e, na pasta `app_escola`, `firebase use app-escola-fda78` **ou** usa explicitamente:

```bash
firebase deploy --only firestore:rules --project app-escola-fda78
```

### Windows PowerShell: «execução de scripts foi desabilitada»

O `npm` instala o Firebase como `firebase.ps1`; o PowerShell pode bloquear esse script.

- **Opção 1 (recomendada):** permitir scripts só para o teu utilizador (abre o PowerShell e corre):
  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
  ```
  Repete o `firebase deploy --only firestore:rules`.

- **Opção 2:** usar **Prompt de Comando (cmd.exe)** em vez do PowerShell e executar o mesmo `firebase deploy` (o `firebase.cmd` não depende do `ExecutionPolicy`).

- **Opção 3:** invocar o `.cmd` diretamente, por exemplo:
  `"%AppData%\npm\firebase.cmd" deploy --only firestore:rules` (a partir da pasta `app_escola`).

### «Localizar aluno» ou relatórios com `permission-denied`

- O **cadastro** grava um documento; **listar** alunos (modal Localizar, relatórios) lê **toda** a coleção `alunos`. As regras têm de permitir `read` a utilizadores autenticados — confirma no Firebase Console → Firestore → **Regras** que estão iguais ao ficheiro `firestore.rules` do repositório e publica de novo se necessário.
- Confirma que o **projeto** do app (`firebase_options.dart` / `projectId`) é o mesmo onde fizeste `firebase deploy` (`.firebaserc`).
- Depois de publicar regras, **recarrega a página** (Ctrl+F5) e volta a abrir «Localizar».

---

## Referência

- [FlutterFire](https://firebase.flutter.dev/)
- Documentação oficial do assistente: `flutterfire configure --help`
