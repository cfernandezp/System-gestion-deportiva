import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/color_equipo.dart';
import '../../data/models/jugador_asignacion_model.dart';

/// Bottom sheet para seleccionar equipo en mobile
/// E003-HU-005: Asignar Equipos
/// CA-005: Asignacion con selector (tap/click)
class SelectorEquipoBottomSheet extends StatelessWidget {
  /// Jugador a asignar
  final JugadorAsignacionModel jugador;

  /// Colores disponibles para asignar
  final List<ColorEquipo> coloresDisponibles;

  /// Callback al seleccionar un equipo
  final void Function(ColorEquipo equipo) onSeleccionar;

  /// Callback al desasignar (devolver a Sin Asignar)
  final void Function()? onDesasignar;

  const SelectorEquipoBottomSheet({
    super.key,
    required this.jugador,
    required this.coloresDisponibles,
    required this.onSeleccionar,
    this.onDesasignar,
  });

  /// Muestra el bottom sheet
  static Future<void> show(
    BuildContext context, {
    required JugadorAsignacionModel jugador,
    required List<ColorEquipo> coloresDisponibles,
    required void Function(ColorEquipo equipo) onSeleccionar,
    void Function()? onDesasignar,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectorEquipoBottomSheet(
        jugador: jugador,
        coloresDisponibles: coloresDisponibles,
        onSeleccionar: (equipo) {
          Navigator.of(context).pop();
          onSeleccionar(equipo);
        },
        onDesasignar: onDesasignar != null
            ? () {
                Navigator.of(context).pop();
                onDesasignar();
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
          ),

          // Header con nombre del jugador
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Row(
              children: [
                _buildAvatar(colorScheme, textTheme),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jugador.equipo != null
                            ? 'Cambiar equipo'
                            : 'Asignar a equipo',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      Text(
                        jugador.displayName,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Equipo actual (si tiene)
          if (jugador.equipo != null)
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: jugador.equipo!.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: jugador.equipo!.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: jugador.equipo!.color,
                      size: DesignTokens.iconSizeM,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Text(
                      'Actualmente en Equipo ${jugador.equipo!.displayName}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: jugador.equipo!.color,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Boton Sin Asignar (solo si tiene equipo y callback disponible)
          if (jugador.equipo != null && onDesasignar != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
              ),
              child: OutlinedButton.icon(
                onPressed: onDesasignar,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                ),
                icon: const Icon(Icons.person_remove),
                label: const Text('Devolver a Sin Asignar'),
              ),
            ),

          if (jugador.equipo != null && onDesasignar != null)
            const SizedBox(height: DesignTokens.spacingM),

          // Titulo
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Selecciona un equipo',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // Botones de equipos
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Row(
              children: coloresDisponibles.map((color) {
                final isCurrentTeam = jugador.equipo == color;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingXs,
                    ),
                    child: _buildEquipoButton(
                      context,
                      color,
                      isCurrentTeam,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SafeArea(
            child: const SizedBox(height: DesignTokens.spacingM),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, TextTheme textTheme) {
    if (jugador.fotoUrl != null && jugador.fotoUrl!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          image: DecorationImage(
            image: NetworkImage(jugador.fotoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final inicial = jugador.displayName.isNotEmpty
        ? jugador.displayName[0].toUpperCase()
        : '?';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: DesignTokens.primaryGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Center(
        child: Text(
          inicial,
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: DesignTokens.fontWeightBold,
          ),
        ),
      ),
    );
  }

  Widget _buildEquipoButton(
    BuildContext context,
    ColorEquipo color,
    bool isCurrentTeam,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: color.color,
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: InkWell(
        onTap: isCurrentTeam ? null : () => onSeleccionar(color),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.spacingM,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: color.borderColor,
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  Icon(
                    Icons.sports_soccer,
                    color: isCurrentTeam
                        ? color.textColor.withValues(alpha: 0.5)
                        : color.textColor,
                    size: DesignTokens.iconSizeL,
                  ),
                  const SizedBox(height: DesignTokens.spacingXs),
                  Text(
                    color.displayName,
                    style: textTheme.labelLarge?.copyWith(
                      color: isCurrentTeam
                          ? color.textColor.withValues(alpha: 0.5)
                          : color.textColor,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ],
              ),
              // Indicador de equipo actual
              if (isCurrentTeam)
                Positioned(
                  top: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: color.color,
                      size: DesignTokens.iconSizeS,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
