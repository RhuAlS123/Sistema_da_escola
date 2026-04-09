import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/app_breakpoints.dart';
import '../cadastro_geral/cadastro_geral_page.dart';
import '../financeiro/cadastro_financeiro_page.dart';
import '../parcelas/controle_parcelas_page.dart';
import '../relatorios/relatorios_page.dart';
import '../providers/app_providers.dart';

/// Corpo das guias (sem [Scaffold] — o pai fornece AppBar / BottomNavigation).
class AppMainShellBody extends ConsumerWidget {
  const AppMainShellBody({super.key});

  static const destinos = [
    _Destino('Cadastro geral', Icons.person_outline),
    _Destino('Financeiro', Icons.payments_outlined),
    _Destino('Parcelas', Icons.calendar_month_outlined),
    _Destino('Relatórios', Icons.assessment_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index =
        ref.watch(mainTabIndexProvider).clamp(0, destinos.length - 1);
    final w = MediaQuery.sizeOf(context).width;
    // Tablet/desktop: NavigationRail; telefone: NavigationBar no scaffold pai.
    final wide = !AppBreakpoints.isMobileWidth(w);

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) =>
                ref.read(mainTabIndexProvider.notifier).state = i,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final d in destinos)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _TabBody(index: index),
          ),
        ],
      );
    }

    return _TabBody(index: index);
  }
}

/// Barra inferior (somente layout estreito).
class AppMainBottomNav extends ConsumerWidget {
  const AppMainBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainTabIndexProvider)
        .clamp(0, AppMainShellBody.destinos.length - 1);
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) =>
          ref.read(mainTabIndexProvider.notifier).state = i,
      destinations: [
        for (final d in AppMainShellBody.destinos)
          NavigationDestination(
            icon: Icon(d.icon),
            label: d.label,
          ),
      ],
    );
  }
}

class _Destino {
  const _Destino(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.index});

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
