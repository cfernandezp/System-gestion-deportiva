import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/jugador_model.dart';
import 'jugador_avatar.dart';

/// Card de jugador para la lista
/// E002-HU-003: CA-002, RN-002
/// Muestra: foto/avatar, apodo, posicion preferida
class JugadorCard extends StatelessWidget {
  final JugadorModel jugador;
  final VoidCallback? onTap;

  const JugadorCard({
    super.key,
    required this.jugador,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Row(
            children: [
              // Avatar (CA-002: foto o avatar generico)
              JugadorAvatar(
                fotoUrl: jugador.fotoUrl,
                nombreCompleto: jugador.nombreCompleto,
                size: 56,
              ),
              const SizedBox(width: DesignTokens.spacingM),

              // Informacion del jugador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Apodo (CA-002)
                    Text(
                      jugador.apodo,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DesignTokens.spacingXxs),

                    // Nombre completo
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

              // Posicion preferida (CA-002, RN-002)
              _buildPosicionChip(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPosicionChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tienePosicion = jugador.posicionPreferida != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: tienePosicion
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _obtenerIconoPosicion(),
            size: DesignTokens.iconSizeS,
            color: tienePosicion
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spacingXs),
          Text(
            jugador.posicionDisplay,
            style: textTheme.labelSmall?.copyWith(
              color: tienePosicion
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  IconData _obtenerIconoPosicion() {
    if (jugador.posicionPreferida == null) {
      return Icons.help_outline;
    }

    switch (jugador.posicionPreferida!.name) {
      case 'arquero':
        return Icons.sports_handball;
      case 'defensa':
        return Icons.shield_outlined;
      case 'mediocampista':
        return Icons.swap_horiz;
      case 'delantero':
        return Icons.sports_soccer;
      default:
        return Icons.person_outline;
    }
  }
}
