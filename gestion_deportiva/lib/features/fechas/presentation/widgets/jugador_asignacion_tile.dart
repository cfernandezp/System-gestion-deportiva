import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/color_equipo.dart';
import '../../data/models/jugador_asignacion_model.dart';

/// Tile de jugador para asignacion de equipos
/// E003-HU-005: Asignar Equipos
/// CA-004: Drag-drop para desktop
/// CA-005: Tap para selector en mobile
///
/// Mejora UX cancha:
/// - Mobile sin asignar: circulos de color inline (1-tap directo)
/// - Mobile modo rapido: tap en el tile completo asigna directo
/// - Mobile asignado: tap abre bottom sheet para reasignar
class JugadorAsignacionTile extends StatelessWidget {
  /// Datos del jugador
  final JugadorAsignacionModel jugador;

  /// Colores disponibles para asignar
  final List<ColorEquipo> coloresDisponibles;

  /// Callback al asignar a un equipo
  final void Function(ColorEquipo equipo) onAsignar;

  /// Si es vista mobile (tap para selector) o desktop (botones inline)
  final bool isMobile;

  /// Equipo seleccionado en modo rapido (null = modo normal)
  final ColorEquipo? equipoRapido;

  const JugadorAsignacionTile({
    super.key,
    required this.jugador,
    required this.coloresDisponibles,
    required this.onAsignar,
    this.isMobile = true,
    this.equipoRapido,
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

  /// Mobile: Tile con circulos de color inline para asignacion de 1 tap
  /// Si equipoRapido != null, un solo tap en el tile asigna directo
  Widget _buildMobileTile(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Modo rapido: tap en toda la fila asigna al equipo seleccionado
    if (equipoRapido != null) {
      return _buildModoRapidoTile(context, colorScheme, textTheme);
    }

    // Modo normal: circulos de color inline
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        child: Row(
          children: [
            _buildAvatar(colorScheme, textTheme, 40),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                jugador.displayName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingXs),
            // Circulos de color inline - 1 tap directo
            ...coloresDisponibles.map((color) {
              return Padding(
                padding: const EdgeInsets.only(left: DesignTokens.spacingXs),
                child: _buildColorCircle(context, color, textTheme),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Tile en modo rapido: tap en toda la fila asigna al equipoRapido
  Widget _buildModoRapidoTile(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: equipoRapido!.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: equipoRapido!.color.withValues(alpha: 0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onAsignar(equipoRapido!);
          },
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            child: Row(
              children: [
                _buildAvatar(colorScheme, textTheme, 40),
                const SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Text(
                    jugador.displayName,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Indicador del equipo destino
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: equipoRapido!.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: equipoRapido!.borderColor,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Circulo de color para asignacion directa de 1 tap
  /// Touch target 36x36dp con 3 letras de abreviatura
  Widget _buildColorCircle(
    BuildContext context,
    ColorEquipo color,
    TextTheme textTheme,
  ) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onAsignar(color);
          },
          customBorder: const CircleBorder(),
          child: Ink(
            decoration: BoxDecoration(
              color: color.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: color.borderColor,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                color.shortLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: color.textColor,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontSize: 10,
                  letterSpacing: 0,
                ),
              ),
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
}
