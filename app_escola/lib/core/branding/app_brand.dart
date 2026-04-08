import 'package:flutter/material.dart';

/// Nome da instituição e recurso de logo (assets).
const String kAppDisplayName = 'SIS Icpro';

const String kLogoAssetPath = 'assets/branding/sis_icpro_logo.png';

/// Título padrão do AppBar: logo + nome.
class BrandedAppBarTitle extends StatelessWidget {
  const BrandedAppBarTitle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 26.0 : 32.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          kLogoAssetPath,
          height: h,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.school_outlined,
            size: h,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        Flexible(
          child: Text(
            kAppDisplayName,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
