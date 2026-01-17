import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/fecha_disponible_model.dart';
import '../../data/models/fecha_model.dart';

/// Widget tarjeta para mostrar resumen de fecha en la lista
/// E003-HU-002: CA-001, CA-006
/// Muestra: fecha, hora, lugar, costo, inscritos, badge si inscrito
class FechaCard extends StatelessWidget {
  /// Datos de la fecha disponible
  final FechaDisponibleModel fecha;

  /// Callback al hacer tap en la tarjeta
  final VoidCallback? onTap;

  /// Indica si mostrar version compacta (mobile)
  final bool compacta;

  const FechaCard({
    super.key,
    required this.fecha,
    this.onTap,
    this.compacta = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: fecha.usuarioInscrito
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: fecha.usuarioInscrito ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(
            compacta ? DesignTokens.spacingM : DesignTokens.spacingL,
          ),
          child: compacta ? _buildCompactLayout(context) : _buildFullLayout(context),
        ),
      ),
    );
  }

  /// Layout compacto para mobile
  Widget _buildCompactLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Fecha y estado
        Row(
          children: [
            // Icono calendario
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Icon(
                Icons.calendar_today,
                size: DesignTokens.iconSizeS,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingS),

            // Fecha formateada
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fecha.fechaFormato,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${fecha.duracionHoras}h - ${fecha.formatoJuego}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Badge estado / inscrito
            _buildEstadoBadge(context),
          ],
        ),

        const SizedBox(height: DesignTokens.spacingM),

        // Info: lugar, costo, inscritos
        Row(
          children: [
            // Lugar
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: DesignTokens.iconSizeS,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: DesignTokens.spacingXs),
                  Expanded(
                    child: Text(
                      fecha.lugar,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: DesignTokens.spacingM),

            // Costo
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.onSurfaceVariant,
                ),
                Text(
                  fecha.costoFormato,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(width: DesignTokens.spacingM),

            // Inscritos
            _buildInscritosChip(context),
          ],
        ),
      ],
    );
  }

  /// Layout completo para desktop
  Widget _buildFullLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        // Icono calendario grande
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            Icons.calendar_month,
            size: DesignTokens.iconSizeL,
            color: colorScheme.primary,
          ),
        ),

        const SizedBox(width: DesignTokens.spacingM),

        // Info principal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fecha y hora
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fecha.fechaFormato,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                  ),
                  _buildEstadoBadge(context),
                ],
              ),

              const SizedBox(height: DesignTokens.spacingXs),

              // Lugar
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: DesignTokens.iconSizeS,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: DesignTokens.spacingXs),
                  Expanded(
                    child: Text(
                      fecha.lugar,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.spacingS),

              // Detalles: duracion, formato, costo, inscritos
              Wrap(
                spacing: DesignTokens.spacingS,
                runSpacing: DesignTokens.spacingXs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Duracion
                  _buildInfoChip(
                    context,
                    icon: Icons.timer_outlined,
                    label: '${fecha.duracionHoras}h',
                  ),

                  // Costo
                  _buildInfoChip(
                    context,
                    icon: Icons.attach_money,
                    label: fecha.costoFormato,
                    destacado: true,
                  ),

                  // Inscritos
                  _buildInscritosChip(context),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: DesignTokens.spacingM),

        // Flecha
        Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  /// Badge de estado o "Ya anotado"
  Widget _buildEstadoBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // CA-004: Indicador "Ya estas anotado" si inscrito
    if (fecha.usuarioInscrito) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingS,
          vertical: DesignTokens.spacingXs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: DesignTokens.iconSizeS,
              color: colorScheme.primary,
            ),
            const SizedBox(width: DesignTokens.spacingXxs),
            Text(
              'Anotado',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
      );
    }

    // CA-005: Badge de estado si no es abierta
    if (fecha.estado != EstadoFecha.abierta) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingS,
          vertical: DesignTokens.spacingXs,
        ),
        decoration: BoxDecoration(
          color: _getEstadoColor(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        ),
        child: Text(
          fecha.estado.displayName,
          style: textTheme.labelSmall?.copyWith(
            color: _getEstadoColor(context),
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Color segun estado de la fecha
  Color _getEstadoColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (fecha.estado) {
      case EstadoFecha.abierta:
        return DesignTokens.successColor;
      case EstadoFecha.cerrada:
        return DesignTokens.accentColor;
      case EstadoFecha.enJuego:
        return colorScheme.tertiary;
      case EstadoFecha.finalizada:
        return colorScheme.onSurfaceVariant;
      case EstadoFecha.cancelada:
        return DesignTokens.errorColor;
    }
  }

  /// CA-006: Chip de inscritos con contador
  Widget _buildInscritosChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final estaLleno = !fecha.hayLugaresDisponibles;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: estaLleno
            ? DesignTokens.errorColor.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            estaLleno ? Icons.people : Icons.people_outline,
            size: DesignTokens.iconSizeS,
            color: estaLleno
                ? DesignTokens.errorColor
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spacingXxs),
          Text(
            fecha.ocupacionDisplay,
            style: textTheme.labelSmall?.copyWith(
              color: estaLleno
                  ? DesignTokens.errorColor
                  : colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Chip de informacion generico
  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool destacado = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeS,
          color: destacado ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.spacingXxs),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: destacado ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: destacado
                ? DesignTokens.fontWeightMedium
                : DesignTokens.fontWeightRegular,
          ),
        ),
      ],
    );
  }
}
