import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Widget para mostrar un item de informacion del perfil
/// CA-002: Datos visibles del perfil
/// CA-003: Campos opcionales vacios muestran "No especificado"
class PerfilInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isOptional;

  const PerfilInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // CA-003: Verificar si es valor "No especificado"
    final isNoEspecificado = value == 'No especificado';

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: DesignTokens.spacingS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Icon(
              icon,
              size: DesignTokens.iconSizeM,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXxs),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: isNoEspecificado
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                    fontStyle: isNoEspecificado
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
