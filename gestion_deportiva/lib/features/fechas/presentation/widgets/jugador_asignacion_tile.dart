import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/color_equipo.dart';
import '../../data/models/jugador_asignacion_model.dart';

/// Tile de jugador para asignacion de equipos
/// E003-HU-005: Asignar Equipos
/// CA-004: Drag-drop para desktop
/// CA-005: Tap para selector en mobile
class JugadorAsignacionTile extends StatelessWidget {
  /// Datos del jugador
  final JugadorAsignacionModel jugador;

  /// Colores disponibles para asignar
  final List<ColorEquipo> coloresDisponibles;

  /// Callback al asignar a un equipo
  final void Function(ColorEquipo equipo) onAsignar;

  /// Si es vista mobile (tap para selector) o desktop (botones inline)
  final bool isMobile;

  const JugadorAsignacionTile({
    super.key,
    required this.jugador,
    required this.coloresDisponibles,
    required this.onAsignar,
    this.isMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isMobile) {
      return _buildMobileTile(context, colorScheme, textTheme);
    } else {
      return _buildDesktopTile(context, colorScheme, textTheme);
    }
  }

  /// Mobile: Tile con tap para abrir selector
  Widget _buildMobileTile(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarSelectorEquipo(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Row(
              children: [
                _buildAvatar(colorScheme, textTheme, 44),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jugador.displayName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (jugador.nombreCompleto != jugador.apodo &&
                          jugador.apodo != null)
                        Text(
                          jugador.nombreCompleto,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Indicador de accion
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Desktop: Tile con botones de colores inline
  Widget _buildDesktopTile(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      child: Row(
        children: [
          // Drag handle
          MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Icon(
              Icons.drag_indicator,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: DesignTokens.iconSizeM,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingS),
          _buildAvatar(colorScheme, textTheme, 36),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jugador.displayName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Botones de colores
          ...coloresDisponibles.map((color) {
            return Padding(
              padding: const EdgeInsets.only(left: DesignTokens.spacingXs),
              child: Tooltip(
                message: 'Asignar a ${color.displayName}',
                child: InkWell(
                  onTap: () => onAsignar(color),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.color,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      border: Border.all(
                        color: color.borderColor,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: color.textColor,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    ColorScheme colorScheme,
    TextTheme textTheme,
    double size,
  ) {
    if (jugador.fotoUrl != null && jugador.fotoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
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
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: DesignTokens.primaryGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Center(
        child: Text(
          inicial,
          style: textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: DesignTokens.fontWeightBold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  void _mostrarSelectorEquipo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SelectorEquipoContent(
        jugador: jugador,
        coloresDisponibles: coloresDisponibles,
        onSeleccionar: (equipo) {
          Navigator.of(context).pop();
          onAsignar(equipo);
        },
      ),
    );
  }
}

/// Contenido del bottom sheet para seleccionar equipo
class _SelectorEquipoContent extends StatelessWidget {
  final JugadorAsignacionModel jugador;
  final List<ColorEquipo> coloresDisponibles;
  final void Function(ColorEquipo equipo) onSeleccionar;

  const _SelectorEquipoContent({
    required this.jugador,
    required this.coloresDisponibles,
    required this.onSeleccionar,
  });

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
                        'Asignar a equipo',
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

          // Botones de equipos
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Row(
              children: coloresDisponibles.map((color) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingXs,
                    ),
                    child: _buildEquipoButton(context, color),
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

  Widget _buildEquipoButton(BuildContext context, ColorEquipo color) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: color.color,
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: InkWell(
        onTap: () => onSeleccionar(color),
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
          child: Column(
            children: [
              Icon(
                Icons.sports_soccer,
                color: color.textColor,
                size: DesignTokens.iconSizeL,
              ),
              const SizedBox(height: DesignTokens.spacingXs),
              Text(
                color.displayName,
                style: textTheme.labelLarge?.copyWith(
                  color: color.textColor,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
