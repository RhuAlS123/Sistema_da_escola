import 'package:flutter/material.dart';

/// Destinos do menu lateral (alinhado ao fluxo do protótipo ICPRO).
class AppNavDestino {
  const AppNavDestino(this.label, this.icon);

  final String label;
  final IconData icon;
}

const List<AppNavDestino> kAppNavDestinos = [
  AppNavDestino('Cadastro geral', Icons.person_outline),
  AppNavDestino('Financeiro', Icons.payments_outlined),
  AppNavDestino('Parcelas', Icons.calendar_month_outlined),
  AppNavDestino('Relatórios', Icons.assessment_outlined),
];

int clampNavIndex(int i) =>
    i.clamp(0, kAppNavDestinos.length - 1);
