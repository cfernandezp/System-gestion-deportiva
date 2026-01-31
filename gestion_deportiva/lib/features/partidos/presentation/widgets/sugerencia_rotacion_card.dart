import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/finalizar_partido_response_model.dart';

/// Card con sugerencia de siguiente partido (rotacion 3 equipos)
/// E004-HU-005: Finalizar Partido
/// CA-004: Sugerencia de rotacion para 3 equipos
///
/// Muestra que equipo entra a jugar y cual continua
/// segun las reglas de rotacion (ganador se queda o pierde sale).
class SugerenciaRotacionCard extends StatelessWidget {
  /// Sugerencia de siguiente partido
  final SugerenciaSiguienteModel sugerencia;

  /// Callback cuando el usuario quiere iniciar el siguiente partido
  final VoidCallback? onIniciarSiguiente;

  const SugerenciaRotacionCard({
    super.key,
    required this.sugerencia,
    this.onIniciarSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final colorEntra = ColorEquipo.fromString(sugerencia.equipoEntra);
    final colorContinua = ColorEquipo.fromString(sugerencia.equipoContinua);

    return Card(
      elevation: 0,
      color: AppColors.programado.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(
          color: AppColors.programado.withValues(alpha: 0.3),
        ),
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
                  Icons.swap_horiz_rounded,
                  color: AppColors.programado,
                  size: DesignTokens.iconSizeM,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Siguiente Partido',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: AppColors.programado,
                  ),
                ),
              ],
            ),

            const SizedBox(height: DesignTokens.spacingM),

            // Texto de sugerencia
            Text(
              sugerencia.sugerenciaTexto,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: DesignTokens.spacingM),

            // Equipos sugeridos
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Equipo que continua
                  _buildEquipoChip(
                    context,
                    label: 'Continua',
                    equipo: sugerencia.equipoContinua,
                    color: colorContinua,
                    icon: Icons.replay,
                  ),

                  // VS
                  Text(
                    'vs',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),

                  // Equipo que entra
                  _buildEquipoChip(
                    context,
                    label: 'Entra',
                    equipo: sugerencia.equipoEntra,
                    color: colorEntra,
                    icon: Icons.login_rounded,
                  ),
                ],
              ),
            ),

            // Boton para iniciar siguiente partido
            if (onIniciarSiguiente != null) ...[
              const SizedBox(height: DesignTokens.spacingM),
              FilledButton.icon(
                onPressed: onIniciarSiguiente,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.programado,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar Siguiente Partido'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEquipoChip(
    BuildContext context, {
    required String label,
    required String equipo,
    required ColorEquipo? color,
    required IconData icon,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Label (Continua/Entra)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: DesignTokens.iconSizeS,
              color: color?.color ?? Colors.grey,
            ),
            const SizedBox(width: DesignTokens.spacingXs),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: color?.color ?? Colors.grey,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingXs),

        // Chip del equipo
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: color?.color ?? Colors.grey,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            boxShadow: [
              BoxShadow(
                color: (color?.color ?? Colors.grey).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            equipo.toUpperCase(),
            style: textTheme.titleMedium?.copyWith(
              color: color?.textColor ?? Colors.white,
              fontWeight: DesignTokens.fontWeightBold,
            ),
          ),
        ),
      ],
    );
  }
}
