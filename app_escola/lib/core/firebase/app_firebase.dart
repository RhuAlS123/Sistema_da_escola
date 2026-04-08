import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// `true` após [initializeAppFirebase] concluir com sucesso.
bool appFirebaseInitialized = false;

/// Inicializa o Firebase. Se `firebase_options.dart` ainda for o stub
/// ([UnsupportedError]), o app segue sem Firebase até rodar `flutterfire configure`.
Future<void> initializeAppFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    appFirebaseInitialized = true;
    if (kDebugMode) {
      debugPrint(
        '[Firebase] OK — apps: ${Firebase.apps.map((a) => a.name).join(", ")}',
      );
    }
  } on UnsupportedError catch (_) {
    appFirebaseInitialized = false;
    if (kDebugMode) {
      debugPrint(
        '[Firebase] Sem credenciais: execute `flutterfire configure` em app_escola '
        '(SETUP_FIREBASE.md).',
      );
    }
  } catch (e, st) {
    appFirebaseInitialized = false;
    if (kDebugMode) {
      debugPrint('[Firebase] Erro: $e\n$st');
    }
  }
}
