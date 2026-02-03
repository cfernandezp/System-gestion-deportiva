import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/resumen_jornada_model.dart';

/// Card contenedor del resumen completo de jornada
/// E004-HU-007: Resumen de Jornada
/// Muestra informacion de la fecha y lista de partidos
class ResumenJornadaCard extends StatelessWidget {
  /// Informacion de la fecha
  final FechaResumenModel? fecha;

  /// Lista de partidos
  final List<PartidoResumenModel> partidos;

  /// Si mostrar header con info de fecha
  final bool mostrarHeader;

  const ResumenJornadaCard({
    super.key,
    this.fecha,
    required this.partidos,
    this.mostrarHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header con info de fecha
          if (mostrarHeader && fecha != null)
            _buildHeader(context),

          // Lista de partidos
          if (partidos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingS,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sports,
                    color: colorScheme.primary,
                    size: DesignTokens.iconSizeM,
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  Text(
                    'Partidos (${partidos.length})',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...partidos.map((p) => _buildPartidoItem(context, p)),
          ] else
            _buildEmptyPartidos(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusL),
          topRight: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: Row(
        children: [
          // Icono de ubicacion
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Icon(
              Icons.location_on,
              color: colorScheme.onPrimaryContainer,
              size: DesignTokens.iconSizeM,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          // Info de fecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fecha!.lugar,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXxs),
                Text(
                  fecha!.fechaFormato,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Badge de equipos
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXxs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.groups,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: DesignTokens.spacingXs),
                Text(
                  '${fecha!.numEquipos} equipos',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartidoItem(BuildContext context, PartidoResumenModel partido) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final colorLocal = ColorEquipo.fromString(partido.equipoLocal);
    final colorVisitante = ColorEquipo.fromString(partido.equipoVisitante);

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          // Marcador principal
          Row(
            children: [
              // Equipo local
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        _capitalize(partido.equipoLocal),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorLocal?.color ?? AppColors.equipoLocal,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                        border: colorLocal == ColorEquipo.blanco
                            ? Border.all(color: Colors.grey.shade400)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Marcador
              Container(
                margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: partido.estaFinalizado
                      ? colorScheme.surfaceContainerHighest
                      : AppColors.enCurso.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${partido.golesLocal}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                        color: partido.golesLocal > partido.golesVisitante
                            ? AppColors.victoria
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
                      child: Text(
                        '-',
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      '${partido.golesVisitante}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                        color: partido.golesVisitante > partido.golesLocal
                            ? AppColors.victoria
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Equipo visitante
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorVisitante?.color ?? AppColors.equipoVisitante,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                        border: colorVisitante == ColorEquipo.blanco
                            ? Border.all(color: Colors.grey.shade400)
                            : null,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Flexible(
                      child: Text(
                        _capitalize(partido.equipoVisitante),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Lista de goleadores del partido
          if (partido.goleadores.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacingS),
            _buildGoleadoresPartido(context, partido),
          ],

          // Estado del partido
          if (!partido.estaFinalizado) ...[
            const SizedBox(height: DesignTokens.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.enCurso.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Text(
                _getEstadoLabel(partido.estado),
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.enCurso,
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoleadoresPartido(BuildContext context, PartidoResumenModel partido) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Separar goleadores por equipo (aproximacion simple)
    // En un caso real, se deberia tener el campo equipo en GoleadorPartidoModel

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_soccer,
            size: DesignTokens.iconSizeS,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spacingXs),
          Expanded(
            child: Text(
              partido.goleadores.map((g) {
                final golText = g.goles > 1 ? ' (${g.goles})' : '';
                final autogolText = g.esAutogol ? ' [AG]' : '';
                return '${g.jugadorNombre}$golText$autogolText';
              }).join(', '),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPartidos(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_outlined,
            size: DesignTokens.iconSizeXl,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Sin partidos',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            'Aun no se han jugado partidos en esta jornada',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _getEstadoLabel(String estado) {
    switch (estado.toLowerCase()) {
      case 'en_curso':
        return 'En curso';
      case 'pausado':
        return 'Pausado';
      case 'programado':
        return 'Programado';
      default:
        return estado;
    }
  }
}
