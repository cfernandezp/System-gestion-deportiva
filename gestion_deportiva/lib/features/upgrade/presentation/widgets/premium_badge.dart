import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Badge reutilizable para indicar features Premium
/// RN-004: Features premium visibles pero bloqueadas con indicador
///
/// Uso:
/// ```dart
/// // Badge inline junto a un texto/opcion
/// PremiumBadge()
///
/// // Badge con texto personalizado
/// PremiumBadge(label: 'Pro')
///
/// // Wrapper que bloquea interaccion y muestra badge
/// PremiumLock(
///   onTap: () => context.push('/upgrade'),
///   child: Text('Formato triangular'),
/// )
/// ```
class PremiumBadge extends StatelessWidget {
  final String label;

  const PremiumBadge({super.key, this.label = 'Pro'});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: 14,
            color: colorScheme.tertiary,
          ),
          const SizedBox(width: DesignTokens.spacingXxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.tertiary,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper que indica que un elemento es Premium
/// Muestra el badge y redirige a upgrade al tocar
/// RN-004: Opciones premium visibles pero deshabilitadas con etiqueta
class PremiumLock extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const PremiumLock({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      child: Opacity(
        opacity: 0.6,
        child: Row(
          children: [
            Expanded(child: child),
            const SizedBox(width: DesignTokens.spacingS),
            Icon(
              Icons.lock_outline,
              size: 16,
              color: colorScheme.tertiary,
            ),
            const SizedBox(width: DesignTokens.spacingXs),
            const PremiumBadge(),
          ],
        ),
      ),
    );
  }
}
