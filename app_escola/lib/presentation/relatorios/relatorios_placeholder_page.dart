import 'package:flutter/material.dart';

/// PASSOS 5.4 — relatórios e PDF.
class RelatoriosPlaceholderPage extends StatelessWidget {
  const RelatoriosPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Relatórios — em construção.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
