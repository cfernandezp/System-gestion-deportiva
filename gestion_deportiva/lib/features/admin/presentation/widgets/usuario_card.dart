import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/usuario_admin_model.dart';

/// Card para mostrar informacion de un usuario en la lista de gestion (Mobile)
/// HU-005: CA-001 - Lista de usuarios con rol actual
///
/// Disenada para usarse en ListView mobile, con altura flexible
/// que evita overflow en los badges.
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
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Avatar + Info + Boton
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar con inicial
              _buildAvatar(colorScheme),
              const SizedBox(width: DesignTokens.spacingM),

              // Informacion del usuario (nombre + email)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nombre + badge "Tu"
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
                        if (isCurrentUser) ...[
                          const SizedBox(width: DesignTokens.spacingXs),
                          Container(
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
                  ],
                ),
              ),

              const SizedBox(width: DesignTokens.spacingS),

              // Boton de cambiar rol
              _buildCambiarRolButton(context, colorScheme),
            ],
          ),

          const SizedBox(height: DesignTokens.spacingM),

          // Fila inferior: Badges de rol y estado
          Row(
            children: [
              _buildRolBadge(),
              const SizedBox(width: DesignTokens.spacingS),
              _buildEstadoBadge(),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    final inicial = usuario.nombreCompleto.isNotEmpty
        ? usuario.nombreCompleto[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 22,
      backgroundColor: _getAvatarColor(colorScheme),
      child: Text(
        inicial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: DesignTokens.fontWeightBold,
          fontSize: DesignTokens.fontSizeM,
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
        iconSize: DesignTokens.iconSizeM,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
    );
  }
}
