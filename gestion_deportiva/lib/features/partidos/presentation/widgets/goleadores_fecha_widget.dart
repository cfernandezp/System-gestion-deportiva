import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/resumen_jornada_model.dart';

/// Widget que muestra la lista de goleadores de la jornada
/// E004-HU-007: Resumen de Jornada
/// CA-003: Lista de goleadores con posicion
class GoleadoresFechaWidget extends StatelessWidget {
  /// Lista de goleadores a mostrar
  final List<GoleadorJornadaModel> goleadores;

  /// Goleador de la fecha (maximo anotador)
  final List<GoleadorFechaModel>? goleadorFecha;

  /// Titulo opcional
  final String? titulo;

  /// Cantidad maxima de goleadores a mostrar (0 = todos)
  final int maxItems;

  const GoleadoresFechaWidget({
    super.key,
    required this.goleadores,
    this.goleadorFecha,
    this.titulo,
    this.maxItems = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (goleadores.isEmpty) {
      return _buildEmptyState(context);
    }

    // Limitar items si se especifica
    final itemsToShow =
        maxItems > 0 ? goleadores.take(maxItems).toList() : goleadores;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titulo
            Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  titulo ?? 'Goleadores',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                const Spacer(),
                // Total de goles
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Text(
                    '${_totalGoles()} goles',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                ),
              ],
            ),

            // Goleador de la fecha destacado
            if (goleadorFecha != null && goleadorFecha!.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.spacingM),
              _buildGoleadorFecha(context),
            ],

            const SizedBox(height: DesignTokens.spacingM),
            const Divider(height: 1),

            // Lista de goleadores
            ...itemsToShow.map((g) => _buildGoleadorItem(context, g)),

            // Indicador si hay mas
            if (maxItems > 0 && goleadores.length > maxItems) ...[
              const SizedBox(height: DesignTokens.spacingS),
              Center(
                child: Text(
                  '+${goleadores.length - maxItems} mas',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoleadorFecha(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.oro.withValues(alpha: 0.2),
            AppColors.oro.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: AppColors.oro.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: AppColors.oro,
                size: DesignTokens.iconSizeS,
              ),
              const SizedBox(width: DesignTokens.spacingXs),
              Text(
                'Goleador de la Fecha',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          ...goleadorFecha!.map((gf) {
            final colorEquipo = ColorEquipo.fromString(gf.equipo);
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spacingXs),
              child: Row(
                children: [
                  // Avatar con color del equipo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorEquipo?.color ?? colorScheme.primary,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                      border: colorEquipo == ColorEquipo.blanco
                          ? Border.all(color: Colors.grey.shade400)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(gf.jugadorNombre),
                        style: textTheme.titleSmall?.copyWith(
                          color: colorEquipo?.textColor ?? Colors.white,
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingM),
                  // Nombre y equipo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gf.jugadorNombre,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                        Text(
                          _capitalize(gf.equipo),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Goles
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingM,
                      vertical: DesignTokens.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.oro,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${gf.goles}',
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.black87,
                            fontWeight: DesignTokens.fontWeightBold,
                          ),
                        ),
                        Text(
                          'goles',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGoleadorItem(BuildContext context, GoleadorJornadaModel goleador) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colorEquipo = ColorEquipo.fromString(goleador.equipo);

    // Color para top 3
    Color? posicionColor;
    if (goleador.posicion == 1) {
      posicionColor = AppColors.oro;
    } else if (goleador.posicion == 2) {
      posicionColor = AppColors.plata;
    } else if (goleador.posicion == 3) {
      posicionColor = AppColors.bronce;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
      child: Row(
        children: [
          // Posicion
          SizedBox(
            width: 32,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (goleador.posicion <= 3)
                  Icon(
                    Icons.emoji_events,
                    size: 14,
                    color: posicionColor,
                  )
                else
                  Text(
                    '${goleador.posicion}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          // Avatar con color del equipo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorEquipo?.color ?? colorScheme.primary,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              border: colorEquipo == ColorEquipo.blanco
                  ? Border.all(color: Colors.grey.shade400)
                  : null,
            ),
            child: Center(
              child: Text(
                _getInitials(goleador.jugadorNombre),
                style: textTheme.labelSmall?.copyWith(
                  color: colorEquipo?.textColor ?? Colors.white,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ),
          ),

          const SizedBox(width: DesignTokens.spacingS),

          // Nombre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goleador.jugadorNombre,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: goleador.posicion <= 3
                        ? DesignTokens.fontWeightSemiBold
                        : DesignTokens.fontWeightMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _capitalize(goleador.equipo),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Goles
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXxs,
            ),
            decoration: BoxDecoration(
              color: goleador.posicion == 1
                  ? AppColors.oro.withValues(alpha: 0.2)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              '${goleador.goles}',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
                color: goleador.posicion == 1
                    ? AppColors.oro
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              size: DesignTokens.iconSizeXl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Sin goleadores',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            Text(
              'Aun no se han registrado goles en esta jornada',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  int _totalGoles() {
    return goleadores.fold(0, (sum, g) => sum + g.goles);
  }
}
