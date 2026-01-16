import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/jugador_model.dart';

/// Boton de ordenamiento para la lista de jugadores
/// E002-HU-003: CA-004, RN-004
class JugadoresSortButton extends StatelessWidget {
  final OrdenCampo ordenCampo;
  final OrdenDireccion ordenDireccion;
  final ValueChanged<OrdenCampo> onCambiarCampo;
  final VoidCallback onAlternarDireccion;

  const JugadoresSortButton({
    super.key,
    required this.ordenCampo,
    required this.ordenDireccion,
    required this.onCambiarCampo,
    required this.onAlternarDireccion,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selector de campo de ordenamiento
        PopupMenuButton<OrdenCampo>(
          initialValue: ordenCampo,
          onSelected: onCambiarCampo,
          tooltip: 'Ordenar por',
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: DesignTokens.spacingXs),
                Text(
                  ordenCampo.displayName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingXxs),
                Icon(
                  Icons.arrow_drop_down,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: OrdenCampo.nombre,
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha,
                    size: DesignTokens.iconSizeS,
                    color: ordenCampo == OrdenCampo.nombre
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  Text(
                    'Nombre',
                    style: TextStyle(
                      color: ordenCampo == OrdenCampo.nombre
                          ? colorScheme.primary
                          : null,
                      fontWeight: ordenCampo == OrdenCampo.nombre
                          ? DesignTokens.fontWeightSemiBold
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: OrdenCampo.fechaIngreso,
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: DesignTokens.iconSizeS,
                    color: ordenCampo == OrdenCampo.fechaIngreso
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  Text(
                    'Fecha de ingreso',
                    style: TextStyle(
                      color: ordenCampo == OrdenCampo.fechaIngreso
                          ? colorScheme.primary
                          : null,
                      fontWeight: ordenCampo == OrdenCampo.fechaIngreso
                          ? DesignTokens.fontWeightSemiBold
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(width: DesignTokens.spacingXs),

        // Boton de direccion
        IconButton(
          onPressed: onAlternarDireccion,
          tooltip: ordenDireccion == OrdenDireccion.asc
              ? 'Ascendente (A-Z)'
              : 'Descendente (Z-A)',
          icon: Icon(
            ordenDireccion == OrdenDireccion.asc
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            size: DesignTokens.iconSizeS,
            color: colorScheme.primary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(DesignTokens.spacingS),
            minimumSize: const Size(36, 36),
          ),
        ),
      ],
    );
  }
}
