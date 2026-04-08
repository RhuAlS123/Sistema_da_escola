import 'package:flutter/material.dart';

/// PASSOS 5.2 — contrato financeiro, bloqueio, parcelas geradas.
class CadastroFinanceiroPlaceholderPage extends StatelessWidget {
  const CadastroFinanceiroPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Cadastro financeiro — em construção (próximo passo do PASSOS-IMPLEMENTACAO.md).',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
