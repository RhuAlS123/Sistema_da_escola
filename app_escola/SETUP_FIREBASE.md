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

## Referência

- [FlutterFire](https://firebase.flutter.dev/)
- Documentação oficial do assistente: `flutterfire configure --help`
