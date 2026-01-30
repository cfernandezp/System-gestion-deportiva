import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/solicitud_pendiente_model.dart';

/// Card para mostrar informacion de una solicitud pendiente
/// E001-HU-006: Gestionar Solicitudes de Registro
///
/// Criterios de Aceptacion:
/// - CA-003: Lista con nombre, email, fecha registro, dias pendiente
class SolicitudCard extends StatelessWidget {
  const SolicitudCard({
    super.key,
    required this.solicitud,
    required this.onAprobar,
    required this.onRechazar,
    this.isProcessing = false,
  });

  /// Solicitud pendiente a mostrar
  final SolicitudPendienteModel solicitud;

  /// Callback al aprobar
  final VoidCallback onAprobar;

  /// Callback al rechazar
  final VoidCallback onRechazar;

  /// Si la solicitud esta siendo procesada
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: Opacity(
        opacity: isProcessing ? 0.6 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con avatar y nombre
            Row(
              children: [
                // Avatar
                _buildAvatar(colorScheme),
                const SizedBox(width: DesignTokens.spacingM),

                // Informacion principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.nombreCompleto,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingXxs),
                      Text(
                        solicitud.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge de dias pendiente
                _buildDiasPendienteBadge(colorScheme, theme),
              ],
            ),

            const SizedBox(height: DesignTokens.spacingM),

            // Informacion adicional
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: DesignTokens.spacingXs),
                Text(
                  'Registro: ${solicitud.fechaRegistroFormateada}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: DesignTokens.spacingL),

            // Botones de accion
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Rechazar',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.small,
                    icon: Icons.close,
                    onPressed: isProcessing ? null : onRechazar,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: AppButton(
                    label: 'Aprobar',
                    variant: AppButtonVariant.success,
                    size: AppButtonSize.small,
                    icon: Icons.check,
                    onPressed: isProcessing ? null : onAprobar,
                    isLoading: isProcessing,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    // Obtener iniciales
    final iniciales = _getIniciales();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: DesignTokens.primaryGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Center(
        child: Text(
          iniciales,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: DesignTokens.fontWeightBold,
            fontSize: DesignTokens.fontSizeL,
          ),
        ),
      ),
    );
  }

  String _getIniciales() {
    if (solicitud.nombreCompleto.isEmpty) return '?';
    final partes = solicitud.nombreCompleto.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return solicitud.nombreCompleto[0].toUpperCase();
  }

  Widget _buildDiasPendienteBadge(ColorScheme colorScheme, ThemeData theme) {
    Color badgeColor;
    Color textColor;

    if (solicitud.esMuyUrgente) {
      // Mas de 7 dias - rojo
      badgeColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
    } else if (solicitud.esUrgente) {
      // Mas de 3 dias - naranja
      badgeColor = DesignTokens.accentColor.withValues(alpha: 0.2);
      textColor = DesignTokens.accentColor;
    } else {
      // Normal
      badgeColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(
        solicitud.diasPendienteTexto,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: DesignTokens.fontWeightMedium,
        ),
      ),
    );
  }
}
