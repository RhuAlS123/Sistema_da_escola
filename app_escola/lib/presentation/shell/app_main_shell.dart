import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cadastro_geral/cadastro_geral_page.dart';
import '../financeiro/cadastro_financeiro_page.dart';
import '../parcelas/controle_parcelas_page.dart';
import '../relatorios/relatorios_page.dart';
import '../providers/app_providers.dart';
import 'app_navigation.dart';

/// Corpo das guias (sem [Scaffold] — o pai fornece layout / menu).
class AppMainShellBody extends ConsumerWidget {
  const AppMainShellBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = clampNavIndex(ref.watch(mainTabIndexProvider));
    return AppMainTabPages(index: index);
  }
}

/// Conteúdo da guia ativa.
class AppMainTabPages extends StatelessWidget {
  const AppMainTabPages({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: index,
      sizing: StackFit.expand,
      children: const [
        CadastroGeralPage(),
        CadastroFinanceiroPage(),
        ControleParcelasPage(),
        RelatoriosPage(),
      ],
    );
  }
}
