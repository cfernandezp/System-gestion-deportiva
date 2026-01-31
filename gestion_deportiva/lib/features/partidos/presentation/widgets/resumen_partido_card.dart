import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/finalizar_partido_response_model.dart';

/// Card con resumen post-partido
/// E004-HU-005: Finalizar Partido
/// CA-005: Resumen con marcador final, goleadores y duracion
class ResumenPartidoCard extends StatelessWidget {
  /// Respuesta completa del partido finalizado
  final FinalizarPartidoResponseModel response;

  const ResumenPartidoCard({
    super.key,
    required this.response,
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
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titulo
            Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.victoria,
                  size: DesignTokens.iconSizeM,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Resumen del Partido',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: DesignTokens.spacingM),

            // Marcador y resultado
            if (response.marcador != null && response.resultado != null)
              _buildMarcadorResultado(context),

            const SizedBox(height: DesignTokens.spacingM),
            const Divider(),
            const SizedBox(height: DesignTokens.spacingM),

            // Goleadores
            if (response.goleadores != null &&
                response.goleadores!.listaCompleta.isNotEmpty)
              _buildGoleadores(context),

            // Duracion
            if (response.duracion != null) ...[
              const SizedBox(height: DesignTokens.spacingM),
              _buildDuracion(context),
            ],

            // Badge de finalizado anticipado
            if (response.finalizadoAnticipado) ...[
              const SizedBox(height: DesignTokens.spacingM),
              _buildBadgeAnticipado(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarcadorResultado(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final marcador = response.marcador!;
    final resultado = response.resultado!;

    final colorLocal = ColorEquipo.fromString(marcador.equipoLocal);
    final colorVisitante = ColorEquipo.fromString(marcador.equipoVisitante);

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Column(
        children: [
          // Marcador
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Equipo local
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingS,
                        vertical: DesignTokens.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: colorLocal?.color ?? AppColors.equipoLocal,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Text(
                        marcador.equipoLocal.toUpperCase(),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorLocal?.textColor ?? Colors.white,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingS),
                    Text(
                      '${marcador.golesLocal}',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                        color: resultado.codigo == 'local'
                            ? AppColors.victoria
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // VS
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
                child: Text(
                  '-',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // Equipo visitante
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingS,
                        vertical: DesignTokens.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color:
                            colorVisitante?.color ?? AppColors.equipoVisitante,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Text(
                        marcador.equipoVisitante.toUpperCase(),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorVisitante?.textColor ?? Colors.white,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingS),
                    Text(
                      '${marcador.golesVisitante}',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                        color: resultado.codigo == 'visitante'
                            ? AppColors.victoria
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.spacingM),

          // Resultado
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: resultado.esEmpate
                  ? AppColors.empate.withValues(alpha: 0.2)
                  : AppColors.victoria.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            child: Text(
              resultado.descripcion,
              style: textTheme.labelLarge?.copyWith(
                color: resultado.esEmpate ? AppColors.empate : AppColors.victoria,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoleadores(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final goleadores = response.goleadores!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.sports_soccer,
              size: DesignTokens.iconSizeS,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            Text(
              'Goles (${goleadores.totalGoles})',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingS),
        ...goleadores.listaCompleta.map((gol) => _buildGolItem(context, gol)),
      ],
    );
  }

  Widget _buildGolItem(BuildContext context, GoleadorResumenModel gol) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colorEquipo = ColorEquipo.fromString(gol.equipo);

    // Construir descripcion semantica para accesibilidad
    final semanticLabel = gol.esAutogol
        ? "Autogol de ${gol.jugadorNombre}, equipo ${gol.equipo}, minuto ${gol.minuto}"
        : "Gol de ${gol.jugadorNombre}, equipo ${gol.equipo}, minuto ${gol.minuto}";

    return Semantics(
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spacingXs),
        child: Row(
          children: [
            // Indicador de color del equipo
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: colorEquipo?.color ?? colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: DesignTokens.spacingS),

            // Minuto
            Container(
              width: 40,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingXs,
                vertical: DesignTokens.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
              ),
              child: Text(
                "${gol.minuto}'",
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingS),

            // Nombre del jugador
            Expanded(
              child: Text(
                gol.jugadorNombre,
                style: textTheme.bodyMedium,
              ),
            ),

            // Badge autogol
            if (gol.esAutogol)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingXs,
                  vertical: DesignTokens.spacingXxs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                ),
                child: Text(
                  'AG',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuracion(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final duracion = response.duracion!;

    return Row(
      children: [
        Icon(
          Icons.timer_outlined,
          size: DesignTokens.iconSizeS,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Text(
          'Duracion: ',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          duracion.realFormato,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        Text(
          ' / ${duracion.programadaMinutos} min',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeAnticipado(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.enCurso.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: AppColors.enCurso.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: DesignTokens.iconSizeS,
            color: AppColors.enCurso,
          ),
          const SizedBox(width: DesignTokens.spacingXs),
          Text(
            'Finalizado anticipadamente',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }
}
