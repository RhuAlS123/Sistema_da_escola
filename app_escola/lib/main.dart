import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'core/firebase/app_firebase.dart';
import 'core/format/app_formats.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = kAppLocale.toLanguageTag();
  await initializeAppFirebase();
  runApp(const ProviderScope(child: AppEscola()));
}
