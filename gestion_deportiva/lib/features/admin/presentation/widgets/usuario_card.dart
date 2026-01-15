import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/usuario_admin_model.dart';

/// Card para mostrar informacion de un usuario en la lista de gestion
/// HU-005: CA-001 - Lista de usuarios con rol actual
class UsuarioCard extends StatelessWidget {
  const UsuarioCard({
    super.key,
    required this.usuario,
    required this.onCambiarRol,
    this.isLoading = false,
    this.isCurrentUser = false,
  });

  /// Datos del usuario a mostrar
  final UsuarioAdminModel usuario;

  /// Callback al presionar cambiar rol
  final VoidCallback onCambiarRol;

  /// Si esta cargando (cambiando rol)
  final bool isLoading;

  /// Si es el usuario actual (CA-004: no puede cambiar su propio rol)
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Row(
        children: [
          // Avatar con inicial
          _buildAvatar(colorScheme),
          const SizedBox(width: DesignTokens.spacingM),

          // Informacion del usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        usuario.nombreCompleto,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: const EdgeInsets.only(left: DesignTokens.spacingXs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingS,
                          vertical: DesignTokens.spacingXxs,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                        ),
                        child: Text(
                          'Tu',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingXxs),

                // Email
                Text(
                  usuario.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: DesignTokens.spacingS),

                // Badges de rol y estado
                Wrap(
                  spacing: DesignTokens.spacingS,
                  runSpacing: DesignTokens.spacingXs,
                  children: [
                    _buildRolBadge(),
                    _buildEstadoBadge(),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: DesignTokens.spacingS),

          // Boton de cambiar rol
          _buildCambiarRolButton(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    final inicial = usuario.nombreCompleto.isNotEmpty
        ? usuario.nombreCompleto[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 24,
      backgroundColor: _getAvatarColor(colorScheme),
      child: Text(
        inicial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: DesignTokens.fontWeightBold,
          fontSize: DesignTokens.fontSizeL,
        ),
      ),
    );
  }

  Color _getAvatarColor(ColorScheme colorScheme) {
    switch (usuario.rol) {
      case 'admin':
        return colorScheme.primary;
      case 'entrenador':
        return DesignTokens.secondaryColor;
      case 'arbitro':
        return DesignTokens.accentColor;
      case 'jugador':
      default:
        return colorScheme.tertiary;
    }
  }

  Widget _buildRolBadge() {
    Color bgColor;
    switch (usuario.rol) {
      case 'admin':
        bgColor = DesignTokens.primaryColor;
        break;
      case 'entrenador':
        bgColor = DesignTokens.secondaryColor;
        break;
      case 'arbitro':
        bgColor = DesignTokens.accentColor;
        break;
      case 'jugador':
      default:
        bgColor = const Color(0xFF64748B);
    }

    return StatusBadge(
      label: usuario.rolFormateado,
      backgroundColor: bgColor,
      size: StatusBadgeSize.small,
      icon: _getRolIcon(),
    );
  }

  IconData _getRolIcon() {
    switch (usuario.rol) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'entrenador':
        return Icons.sports;
      case 'arbitro':
        return Icons.gavel;
      case 'jugador':
      default:
        return Icons.person;
    }
  }

  Widget _buildEstadoBadge() {
    StatusBadgeType type;
    switch (usuario.estado) {
      case 'aprobado':
        type = StatusBadgeType.activo;
        break;
      case 'pendiente':
        type = StatusBadgeType.enCurso;
        break;
      case 'rechazado':
        type = StatusBadgeType.derrota;
        break;
      default:
        type = StatusBadgeType.inactivo;
    }

    return StatusBadge(
      label: usuario.estadoFormateado,
      type: type,
      size: StatusBadgeSize.small,
    );
  }

  Widget _buildCambiarRolButton(BuildContext context, ColorScheme colorScheme) {
    // CA-004: Deshabilitado para el usuario actual
    final enabled = !isCurrentUser && !isLoading;

    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Tooltip(
      message: isCurrentUser
          ? 'No puedes cambiar tu propio rol'
          : 'Cambiar rol',
      child: IconButton(
        onPressed: enabled ? onCambiarRol : null,
        icon: Icon(
          Icons.edit_outlined,
          color: enabled
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: DesignTokens.opacityDisabled),
        ),
      ),
    );
  }
}
