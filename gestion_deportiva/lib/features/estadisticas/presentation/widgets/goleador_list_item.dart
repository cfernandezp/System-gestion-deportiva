import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/ranking_goleador_model.dart';

/// Widget para mostrar un goleador en la lista (posicion 4+)
/// CA-002: Informacion por jugador (posicion, foto/avatar, apodo, goles, partidos, promedio)
/// CA-005: Mi posicion destacada
class GoleadorListItem extends StatelessWidget {
  /// Datos del goleador
  final RankingGoleadorModel goleador;

  /// Indica si es el usuario actual (para destacar - CA-005)
  final bool isCurrentUser;

  /// Callback al tocar el item (opcional)
  final VoidCallback? onTap;

  const GoleadorListItem({
    super.key,
    required this.goleador,
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: isCurrentUser
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isCurrentUser ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Posicion
              _PosicionBadge(posicion: goleador.posicion),

              const SizedBox(width: DesignTokens.spacingM),

              // Avatar
              _Avatar(
                avatarUrl: goleador.avatarUrl,
                iniciales: goleador.iniciales,
                tieneAvatar: goleador.tieneAvatar,
              ),

              const SizedBox(width: DesignTokens.spacingM),

              // Nombre/Apodo y stats secundarias
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goleador.apodo,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: DesignTokens.fontWeightSemiBold,
                              color: isCurrentUser
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            margin: const EdgeInsets.only(left: DesignTokens.spacingS),
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacingS,
                              vertical: DesignTokens.spacingXxs,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                            ),
                            child: Text(
                              'Tu',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: DesignTokens.fontWeightBold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spacingXxs),
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.sports,
                          label: '${goleador.partidosJugados} PJ',
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: DesignTokens.spacingS),
                        _StatChip(
                          icon: Icons.trending_up,
                          label: 'Prom: ${goleador.promedioFormateado}',
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: DesignTokens.spacingM),

              // Goles (destacado)
              _GolesIndicador(goles: goleador.goles),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge de posicion en el ranking
class _PosicionBadge extends StatelessWidget {
  final int posicion;

  const _PosicionBadge({required this.posicion});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Center(
        child: Text(
          '#$posicion',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Avatar del jugador
class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String iniciales;
  final bool tieneAvatar;

  const _Avatar({
    this.avatarUrl,
    required this.iniciales,
    required this.tieneAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: tieneAvatar
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(colorScheme),
              )
            : _buildPlaceholder(colorScheme),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Text(
          iniciales,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Chip de estadistica secundaria
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeS - 2,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.spacingXxs),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Indicador de goles destacado
class _GolesIndicador extends StatelessWidget {
  final int goles;

  const _GolesIndicador({required this.goles});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_soccer,
            size: DesignTokens.iconSizeS,
            color: colorScheme.primary,
          ),
          const SizedBox(width: DesignTokens.spacingXs),
          Text(
            '$goles',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
