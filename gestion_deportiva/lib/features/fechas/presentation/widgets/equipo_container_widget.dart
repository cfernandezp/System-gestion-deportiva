import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/color_equipo.dart';
import '../../data/models/jugador_asignacion_model.dart';

/// Widget contenedor de un equipo con sus jugadores asignados
/// E003-HU-005: Asignar Equipos
/// CA-001: Equipos disponibles a la derecha (con colores)
/// CA-003: Colores distintivos de equipos
/// CA-004: DragTarget para recibir jugadores en desktop
class EquipoContainerWidget extends StatelessWidget {
  /// Color del equipo
  final ColorEquipo equipo;

  /// Lista de jugadores asignados al equipo
  final List<JugadorAsignacionModel> jugadores;

  /// Callback al remover/reasignar un jugador del equipo
  final void Function(JugadorAsignacionModel jugador)? onJugadorRemover;

  /// Callback al recibir un jugador por drag-drop (desktop)
  final void Function(JugadorAsignacionModel jugador)? onJugadorDrop;

  /// Si es vista mobile o desktop
  final bool isMobile;

  const EquipoContainerWidget({
    super.key,
    required this.equipo,
    required this.jugadores,
    this.onJugadorRemover,
    this.onJugadorDrop,
    this.isMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _buildMobileContainer(context);
    } else {
      return _buildDesktopContainer(context);
    }
  }

  /// Mobile: Card simple con lista de jugadores
  Widget _buildMobileContainer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: equipo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: equipo.color.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con color del equipo
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: equipo.color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusM - 2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  color: equipo.textColor,
                  size: DesignTokens.iconSizeM,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Equipo ${equipo.displayName}',
                  style: textTheme.titleSmall?.copyWith(
                    color: equipo.textColor,
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Text(
                    '${jugadores.length}',
                    style: textTheme.labelLarge?.copyWith(
                      color: equipo.textColor,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de jugadores
          if (jugadores.isEmpty)
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingL),
              child: Center(
                child: Text(
                  'Sin jugadores asignados',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: jugadores.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: equipo.color.withValues(alpha: 0.2),
              ),
              itemBuilder: (context, index) {
                final jugador = jugadores[index];
                return _buildJugadorTile(context, jugador, colorScheme, textTheme);
              },
            ),
        ],
      ),
    );
  }

  /// Desktop: Card con DragTarget para recibir jugadores
  Widget _buildDesktopContainer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // CA-004: DragTarget para recibir jugadores
    return DragTarget<JugadorAsignacionModel>(
      onWillAcceptWithDetails: (details) {
        // Aceptar si el jugador no esta ya en este equipo
        return details.data.equipo != equipo;
      },
      onAcceptWithDetails: (details) {
        onJugadorDrop?.call(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: DesignTokens.animFast,
          decoration: BoxDecoration(
            color: isHovering
                ? equipo.color.withValues(alpha: 0.2)
                : equipo.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: isHovering
                  ? equipo.color
                  : equipo.color.withValues(alpha: 0.5),
              width: isHovering ? 3 : 2,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: equipo.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con color del equipo
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: equipo.color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(DesignTokens.radiusL - 2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      color: equipo.textColor,
                      size: DesignTokens.iconSizeM,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Text(
                      'Equipo ${equipo.displayName}',
                      style: textTheme.titleSmall?.copyWith(
                        color: equipo.textColor,
                        fontWeight: DesignTokens.fontWeightBold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingM,
                        vertical: DesignTokens.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                      ),
                      child: Text(
                        '${jugadores.length} jugador${jugadores.length != 1 ? 'es' : ''}',
                        style: textTheme.labelLarge?.copyWith(
                          color: equipo.textColor,
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Indicador de drop zone
              if (isHovering)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  color: equipo.color.withValues(alpha: 0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: equipo.color,
                        size: DesignTokens.iconSizeM,
                      ),
                      const SizedBox(width: DesignTokens.spacingS),
                      Text(
                        'Soltar aqui para asignar',
                        style: textTheme.bodyMedium?.copyWith(
                          color: equipo.color,
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                ),

              // Lista de jugadores
              if (jugadores.isEmpty && !isHovering)
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingL),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_add_outlined,
                          size: DesignTokens.iconSizeXl,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: DesignTokens.spacingS),
                        Text(
                          'Arrastra jugadores aqui',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (jugadores.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: jugadores.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: equipo.color.withValues(alpha: 0.2),
                  ),
                  itemBuilder: (context, index) {
                    final jugador = jugadores[index];
                    return _buildJugadorTileDesktop(
                      context,
                      jugador,
                      colorScheme,
                      textTheme,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Tile de jugador para mobile
  Widget _buildJugadorTile(
    BuildContext context,
    JugadorAsignacionModel jugador,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return InkWell(
      onTap: onJugadorRemover != null ? () => onJugadorRemover!(jugador) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        child: Row(
          children: [
            _buildAvatar(jugador, textTheme, 36),
            const SizedBox(width: DesignTokens.spacingM),
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
            if (onJugadorRemover != null)
              Icon(
                Icons.swap_horiz,
                color: colorScheme.onSurfaceVariant,
                size: DesignTokens.iconSizeS,
              ),
          ],
        ),
      ),
    );
  }

  /// Tile de jugador para desktop con opcion de reasignar
  Widget _buildJugadorTileDesktop(
    BuildContext context,
    JugadorAsignacionModel jugador,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return InkWell(
      onTap: onJugadorRemover != null ? () => onJugadorRemover!(jugador) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        child: Row(
          children: [
            _buildAvatar(jugador, textTheme, 32),
            const SizedBox(width: DesignTokens.spacingM),
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
            if (onJugadorRemover != null)
              Tooltip(
                message: 'Cambiar de equipo',
                child: IconButton(
                  onPressed: () => onJugadorRemover!(jugador),
                  icon: Icon(
                    Icons.swap_horiz,
                    color: colorScheme.onSurfaceVariant,
                    size: DesignTokens.iconSizeS,
                  ),
                  iconSize: DesignTokens.iconSizeS,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(
    JugadorAsignacionModel jugador,
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
          border: Border.all(
            color: equipo.color,
            width: 2,
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
        color: equipo.color,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Center(
        child: Text(
          inicial,
          style: textTheme.labelLarge?.copyWith(
            color: equipo.textColor,
            fontWeight: DesignTokens.fontWeightBold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}
