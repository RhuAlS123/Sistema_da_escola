import 'package:flutter/material.dart';

/// PASSOS 5.3 — parcelas, juros, cores de status.
class ControleParcelasPlaceholderPage extends StatelessWidget {
  const ControleParcelasPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Controle de parcelas — em construção.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
