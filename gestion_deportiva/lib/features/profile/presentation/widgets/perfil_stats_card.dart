import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Widget para mostrar estadistica del perfil
/// RN-005: Muestra antiguedad en el grupo
class PerfilStatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const PerfilStatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        boxShadow: isDark ? DesignTokens.shadowSmDark : DesignTokens.shadowSm,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeL,
            color: colorScheme.primary,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingXxs),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
