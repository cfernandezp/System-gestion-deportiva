import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/ranking_goleador_model.dart';

/// Widget que muestra el podio del top 3 de goleadores
/// CA-006: Top 3 destacado (Podio)
/// - 1ro: Medalla oro, posicion central/superior
/// - 2do: Medalla plata, izquierda
/// - 3ro: Medalla bronce, derecha
class PodioGoleadoresWidget extends StatelessWidget {
  /// Lista del top 3 goleadores
  final List<RankingGoleadorModel> top3;

  /// ID del usuario actual para destacar (CA-005)
  final String? currentUserId;

  const PodioGoleadoresWidget({
    super.key,
    required this.top3,
    this.currentUserId,
  });

  // Colores de medallas
  static const Color _oroColor = Color(0xFFFFD700);
  static const Color _plataColor = Color(0xFFC0C0C0);
  static const Color _bronceColor = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Obtener goleadores por posicion (pueden no existir todos)
    final primero = top3.firstWhere(
      (g) => g.posicion == 1,
      orElse: () => top3.first,
    );
    final segundo = top3.length > 1
        ? top3.firstWhere((g) => g.posicion == 2, orElse: () => top3[1])
        : null;
    final tercero = top3.length > 2
        ? top3.firstWhere((g) => g.posicion == 3, orElse: () => top3[2])
        : null;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Titulo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                color: _oroColor,
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                'PODIO DE GOLEADORES',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                  letterSpacing: 1.5,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Icon(
                Icons.emoji_events,
                color: _oroColor,
                size: DesignTokens.iconSizeM,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Podio visual
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Segundo lugar (plata) - izquierda
              if (segundo != null)
                _PodioItem(
                  goleador: segundo,
                  medallaColor: _plataColor,
                  altura: 100,
                  isCurrentUser: segundo.jugadorId == currentUserId,
                )
              else
                const SizedBox(width: 100),

              const SizedBox(width: DesignTokens.spacingM),

              // Primer lugar (oro) - centro, mas alto
              _PodioItem(
                goleador: primero,
                medallaColor: _oroColor,
                altura: 130,
                isCurrentUser: primero.jugadorId == currentUserId,
              ),

              const SizedBox(width: DesignTokens.spacingM),

              // Tercer lugar (bronce) - derecha
              if (tercero != null)
                _PodioItem(
                  goleador: tercero,
                  medallaColor: _bronceColor,
                  altura: 80,
                  isCurrentUser: tercero.jugadorId == currentUserId,
                )
              else
                const SizedBox(width: 100),
            ],
          ),
        ],
      ),
    );
  }
}

/// Item individual del podio
class _PodioItem extends StatelessWidget {
  final RankingGoleadorModel goleador;
  final Color medallaColor;
  final double altura;
  final bool isCurrentUser;

  const _PodioItem({
    required this.goleador,
    required this.medallaColor,
    required this.altura,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar con medalla
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentUser ? colorScheme.primary : medallaColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: medallaColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: goleador.tieneAvatar
                    ? Image.network(
                        goleador.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(colorScheme),
                      )
                    : _buildAvatarPlaceholder(colorScheme),
              ),
            ),

            // Medalla posicionada arriba
            Positioned(
              top: -12,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: medallaColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${goleador.posicion}',
                    style: textTheme.labelMedium?.copyWith(
                      color: goleador.posicion == 1 ? Colors.black : Colors.white,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.spacingS),

        // Nombre/Apodo
        SizedBox(
          width: 100,
          child: Text(
            goleador.apodo,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: isCurrentUser ? colorScheme.primary : colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: DesignTokens.spacingXs),

        // Goles con icono
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_soccer,
              size: DesignTokens.iconSizeS,
              color: colorScheme.primary,
            ),
            const SizedBox(width: DesignTokens.spacingXxs),
            Text(
              '${goleador.goles}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.spacingS),

        // Pedestal
        Container(
          width: 100,
          height: altura,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medallaColor,
                medallaColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DesignTokens.radiusS),
              topRight: Radius.circular(DesignTokens.radiusS),
            ),
            boxShadow: [
              BoxShadow(
                color: medallaColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${goleador.partidosJugados}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                    color: goleador.posicion == 1 ? Colors.black87 : Colors.white,
                  ),
                ),
                Text(
                  'partidos',
                  style: textTheme.labelSmall?.copyWith(
                    color: goleador.posicion == 1
                        ? Colors.black54
                        : Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Text(
                    'Prom: ${goleador.promedioFormateado}',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: goleador.posicion == 1 ? Colors.black87 : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Text(
          goleador.iniciales,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
