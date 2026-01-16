import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Estado vacio para la lista de jugadores
/// E002-HU-003: RN-001, RN-003
class JugadoresEmptyState extends StatelessWidget {
  final bool tieneBusqueda;
  final VoidCallback? onLimpiarBusqueda;

  const JugadoresEmptyState({
    super.key,
    this.tieneBusqueda = false,
    this.onLimpiarBusqueda,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tieneBusqueda ? Icons.search_off : Icons.group_outlined,
              size: DesignTokens.iconSizeXxl,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              tieneBusqueda
                  ? 'No se encontraron jugadores'
                  : 'Sin jugadores',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              tieneBusqueda
                  ? 'Intenta con otro termino de busqueda'
                  : 'Aun no hay jugadores aprobados en el grupo',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (tieneBusqueda && onLimpiarBusqueda != null) ...[
              const SizedBox(height: DesignTokens.spacingL),
              OutlinedButton.icon(
                onPressed: onLimpiarBusqueda,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar busqueda'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
