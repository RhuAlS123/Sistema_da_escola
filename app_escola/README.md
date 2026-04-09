# SIS Icpro — app Flutter

Gestão escolar: cadastro, contrato financeiro, parcelas, relatórios e PDF.

## Desenvolvimento

```bash
flutter pub get
flutter run -d chrome
# ou: flutter run -d android
```

## Firebase (novo clone ou outro PC)

1. Instale [FlutterFire CLI](https://firebase.flutter.dev/): `dart pub global activate flutterfire_cli`
2. Na pasta `app_escola`: `flutterfire configure` e escolha o projeto (gera `lib/firebase_options.dart` e ajusta `google-services.json`, etc.).
3. No [Firebase Console](https://console.firebase.google.com/): ative **Authentication** (e-mail/senha) e crie **Firestore**.
4. **Regras Firestore:** publique o ficheiro `firestore.rules` deste repositório:

   ```bash
   cd app_escola
   firebase deploy --only firestore:rules
   ```

   Projeto predefinido: `.firebaserc` (ex.: `app-escola-fda78`). No PowerShell, se `firebase` falhar por política de scripts, use o `cmd` ou `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

5. **Utilizadores:** os e-mails de login estão em `lib/core/auth/fixed_auth_mapping.dart` (`colab1@escola.com`, `colab2@escola.com`, `admin@escola.com`). Crie-os no Firebase Authentication. Em Firestore, coleção `usuarios`, um documento por utilizador com **ID = UID** do Auth e campos `nome` (texto) e `role` (`colab` ou `admin`).

   Opcional: script em `tools/seed_usuarios/` (Node.js + conta de serviço JSON fora do Git). Ver `package.json` e `seed.mjs`.

## Marca e ícone (launcher / PWA)

Logo: `assets/branding/sis_icpro_logo.png`. Depois de alterar:

```bash
dart run flutter_launcher_icons
```

Depois gere novo build (`flutter build apk`, `flutter build web`, …).

## Build de produção

| Plataforma | Comando | Saída |
|------------|---------|--------|
| Web | `flutter build web` | `build/web/` |
| APK | `flutter build apk` | `build/app/outputs/flutter-apk/app-release.apk` |
| Play Store | `flutter build appbundle` | `build/app/outputs/bundle/release/app-release.aab` |
| iOS | macOS + Xcode | `flutter build ipa` (antes: `flutterfire configure` no Mac) |

## Repositório

Artefactos de build e ficheiros sensíveis estão no `.gitignore` da raiz do projeto.
