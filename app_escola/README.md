# SIS Icpro — app Flutter

Gestão escolar: cadastro, contrato financeiro, parcelas, relatórios e PDF.

## Rodar em desenvolvimento

Na pasta **`app_escola`**:

```bash
flutter pub get
flutter run -d chrome
# ou: flutter run -d android
```

Firebase: o projeto inclui `lib/firebase_options.dart`. Noutro PC, se precisar reconfigurar, siga **`SETUP_FIREBASE.md`**.

## Build de produção

| Plataforma | Comando |
|------------|---------|
| **Web** | `flutter build web` — saída em `build/web/` (servir com hosting estático ou Firebase Hosting). |
| **APK** | `flutter build apk` — `build/app/outputs/flutter-apk/app-release.apk`. |
| **App Bundle (Play Store)** | `flutter build appbundle` — `build/app/outputs/bundle/release/app-release.aab`. |
| **iOS** | Requer macOS com Xcode: `flutter build ipa` (ou abrir `ios/` no Xcode). Rode antes `flutterfire configure` no Mac para `GoogleService-Info.plist`. |

Depois do build web, pode publicar regras Firestore: `firebase deploy --only firestore:rules` (ver **`SETUP_FIREBASE.md`** §5).

## Checklist manual de QA (Fase 7)

1. Login → carregar perfil e guias.  
2. Cadastro geral → salvar / autosave ao mudar de guia.  
3. Cadastro financeiro → primeiro save bloqueia; admin desbloqueia com senha.  
4. **(Admin)** Excluir aluno no financeiro (confirmação) → documento e parcelas apagados no Firestore.  
5. Parcelas → editar e salvar; cores de status.  
6. Relatórios → filtros e exportar PDF.

## Repositório e segredos

- Use **Git** na raiz do projeto; o `.gitignore` ignora artefactos de build e ficheiros locais comuns.  
- Variáveis locais (futuro): ficheiros `.env` / `.env.*` estão ignorados — prefira `flutterfire`/opções geradas em vez de API keys em texto livre.
