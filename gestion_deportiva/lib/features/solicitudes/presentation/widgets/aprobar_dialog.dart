import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';

/// Roles disponibles para aprobar usuarios
/// E001-HU-006: CA-005 - Aprobar con seleccion de rol
class RolAprobacionOption {
  final String value;
  final String label;
  final String descripcion;
  final IconData icon;
  final Color color;

  const RolAprobacionOption({
    required this.value,
    required this.label,
    required this.descripcion,
    required this.icon,
    required this.color,
  });

  /// Roles disponibles para aprobar usuarios
  /// CA-005: jugador (default), admin, arbitro, delegado
  static const List<RolAprobacionOption> roles = [
    RolAprobacionOption(
      value: 'jugador',
      label: 'Jugador',
      descripcion: 'Participante en pichangas y torneos',
      icon: Icons.person,
      color: Color(0xFF64748B),
    ),
    RolAprobacionOption(
      value: 'admin',
      label: 'Administrador',
      descripcion: 'Acceso total al sistema',
      icon: Icons.admin_panel_settings,
      color: DesignTokens.primaryColor,
    ),
    RolAprobacionOption(
      value: 'arbitro',
      label: 'Arbitro',
      descripcion: 'Gestiona partidos asignados',
      icon: Icons.gavel,
      color: DesignTokens.accentColor,
    ),
    RolAprobacionOption(
      value: 'delegado',
      label: 'Delegado',
      descripcion: 'Representa y gestiona equipos',
      icon: Icons.badge,
      color: DesignTokens.secondaryColor,
    ),
  ];
}

/// Dialog para confirmar aprobacion de usuario
/// E001-HU-006: CA-005 - Aprobar con seleccion de rol
/// CA-008: Dialogos de confirmacion
class AprobarDialog extends StatefulWidget {
  const AprobarDialog({
    super.key,
    required this.nombreUsuario,
    required this.onConfirmar,
  });

  /// Nombre del usuario a aprobar
  final String nombreUsuario;

  /// Callback al confirmar con el rol seleccionado
  final void Function(String rol) onConfirmar;

  /// Muestra el dialog y retorna el rol seleccionado o null si cancela
  static Future<String?> show({
    required BuildContext context,
    required String nombreUsuario,
  }) async {
    String? rolSeleccionado;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AprobarDialog(
        nombreUsuario: nombreUsuario,
        onConfirmar: (rol) {
          rolSeleccionado = rol;
          Navigator.of(dialogContext).pop();
        },
      ),
    );

    return rolSeleccionado;
  }

  @override
  State<AprobarDialog> createState() => _AprobarDialogState();
}

class _AprobarDialogState extends State<AprobarDialog> {
  // Default: jugador (CA-005)
  String _rolSeleccionado = 'jugador';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titulo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spacingS),
                      decoration: BoxDecoration(
                        color: DesignTokens.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: DesignTokens.successColor,
                        size: DesignTokens.iconSizeL,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        'Aprobar usuario',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingS),

                // Subtitulo
                Text(
                  'Selecciona el rol para ${widget.nombreUsuario}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingL),

                // Lista de roles
                ...RolAprobacionOption.roles.map(
                  (rol) => _buildRolTile(rol, colorScheme, theme),
                ),

                const SizedBox(height: DesignTokens.spacingL),

                // Mensaje informativo
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.onSurfaceVariant,
                        size: DesignTokens.iconSizeM,
                      ),
                      const SizedBox(width: DesignTokens.spacingS),
                      Expanded(
                        child: Text(
                          'El usuario recibira un email notificando su aprobacion',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingL),

                // Botones de accion
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancelar',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingM),
                    Expanded(
                      child: AppButton(
                        label: 'Aprobar',
                        variant: AppButtonVariant.success,
                        icon: Icons.check,
                        onPressed: () => widget.onConfirmar(_rolSeleccionado),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRolTile(
    RolAprobacionOption rol,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isSelected = _rolSeleccionado == rol.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: InkWell(
          onTap: () {
            setState(() {
              _rolSeleccionado = rol.value;
            });
          },
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Row(
              children: [
                // Icono del rol
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingS),
                  decoration: BoxDecoration(
                    color: rol.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Icon(
                    rol.icon,
                    color: rol.color,
                    size: DesignTokens.iconSizeM,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),

                // Informacion del rol
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rol.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingXxs),
                      Text(
                        rol.descripcion,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Radio indicator
                Radio<String>(
                  value: rol.value,
                  groupValue: _rolSeleccionado,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _rolSeleccionado = value;
                      });
                    }
                  },
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
