import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/resumen_jornada_model.dart';

/// Widget que muestra las estadisticas generales de la jornada
/// E004-HU-007: Resumen de Jornada
class EstadisticasJornadaWidget extends StatelessWidget {
  /// Estadisticas a mostrar
  final EstadisticasJornadaModel estadisticas;

  /// Mostrar en modo compacto (horizontal)
  final bool compacto;

  const EstadisticasJornadaWidget({
    super.key,
    required this.estadisticas,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (compacto) {
      return _buildCompacto(context);
    }

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
                  Icons.insights,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Estadisticas',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingM),

            // Grid de estadisticas
            Wrap(
              spacing: DesignTokens.spacingM,
              runSpacing: DesignTokens.spacingM,
              children: [
                _buildStatCard(
                  context,
                  icon: Icons.sports_soccer,
                  label: 'Partidos',
                  value: '${estadisticas.partidosFinalizados}/${estadisticas.totalPartidos}',
                  color: colorScheme.primary,
                  subtitle: '${estadisticas.porcentajeCompletado.toStringAsFixed(0)}% completados',
                ),
                _buildStatCard(
                  context,
                  icon: Icons.emoji_events,
                  label: 'Goles',
                  value: '${estadisticas.totalGoles}',
                  color: AppColors.victoria,
                ),
                _buildStatCard(
                  context,
                  icon: Icons.show_chart,
                  label: 'Promedio',
                  value: estadisticas.promedioGolesPartido.toStringAsFixed(1),
                  color: AppColors.enCurso,
                  subtitle: 'goles/partido',
                ),
              ],
            ),

            // Partido con mas goles
            if (estadisticas.partidoMasGoles != null) ...[
              const SizedBox(height: DesignTokens.spacingM),
              const Divider(),
              const SizedBox(height: DesignTokens.spacingS),
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: AppColors.enCurso,
                    size: DesignTokens.iconSizeS,
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partido mas goleado',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          estadisticas.partidoMasGoles!,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: DesignTokens.fontWeightMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompacto(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCompact(
            context,
            icon: Icons.sports_soccer,
            value: '${estadisticas.partidosFinalizados}/${estadisticas.totalPartidos}',
            label: 'Partidos',
          ),
          _buildDivider(context),
          _buildStatCompact(
            context,
            icon: Icons.emoji_events,
            value: '${estadisticas.totalGoles}',
            label: 'Goles',
          ),
          _buildDivider(context),
          _buildStatCompact(
            context,
            icon: Icons.show_chart,
            value: estadisticas.promedioGolesPartido.toStringAsFixed(1),
            label: 'Promedio',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: DesignTokens.iconSizeM,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: DesignTokens.spacingXxs),
            Text(
              subtitle,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCompact(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: DesignTokens.iconSizeS,
              color: colorScheme.primary,
            ),
            const SizedBox(width: DesignTokens.spacingXs),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      height: 32,
      color: colorScheme.outlineVariant,
    );
  }
}
