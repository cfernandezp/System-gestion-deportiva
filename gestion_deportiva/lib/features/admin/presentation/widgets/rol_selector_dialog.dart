import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';

/// Roles disponibles en el sistema
/// HU-005: CA-003 - Roles disponibles: Admin, Entrenador, Jugador, Arbitro
/// RN-001: Solo existen cuatro roles validos
class RolOption {
  final String value;
  final String label;
  final String descripcion;
  final IconData icon;
  final Color color;

  const RolOption({
    required this.value,
    required this.label,
    required this.descripcion,
    required this.icon,
    required this.color,
  });

  static const List<RolOption> roles = [
    RolOption(
      value: 'admin',
      label: 'Administrador',
      descripcion: 'Acceso total al sistema',
      icon: Icons.admin_panel_settings,
      color: DesignTokens.primaryColor,
    ),
    RolOption(
      value: 'entrenador',
      label: 'Entrenador',
      descripcion: 'Gestiona equipos y jugadores asignados',
      icon: Icons.sports,
      color: DesignTokens.secondaryColor,
    ),
    RolOption(
      value: 'jugador',
      label: 'Jugador',
      descripcion: 'Ve su informacion y estadisticas',
      icon: Icons.person,
      color: Color(0xFF64748B),
    ),
    RolOption(
      value: 'arbitro',
      label: 'Arbitro',
      descripcion: 'Gestiona partidos asignados',
      icon: Icons.gavel,
      color: DesignTokens.accentColor,
    ),
  ];
}

/// Dialog para seleccionar un nuevo rol para un usuario
/// HU-005: CA-002 - Cambiar rol de usuario
class RolSelectorDialog extends StatefulWidget {
  const RolSelectorDialog({
    super.key,
    required this.nombreUsuario,
    required this.rolActual,
    required this.onConfirmar,
  });

  /// Nombre del usuario a modificar
  final String nombreUsuario;

  /// Rol actual del usuario
  final String rolActual;

  /// Callback al confirmar cambio
  final void Function(String nuevoRol) onConfirmar;

  /// Muestra el dialog y retorna el rol seleccionado o null si cancela
  static Future<String?> show({
    required BuildContext context,
    required String nombreUsuario,
    required String rolActual,
  }) async {
    String? rolSeleccionado;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RolSelectorDialog(
        nombreUsuario: nombreUsuario,
        rolActual: rolActual,
        onConfirmar: (nuevoRol) {
          rolSeleccionado = nuevoRol;
          Navigator.of(dialogContext).pop();
        },
      ),
    );

    return rolSeleccionado;
  }

  @override
  State<RolSelectorDialog> createState() => _RolSelectorDialogState();
}

class _RolSelectorDialogState extends State<RolSelectorDialog> {
  late String _rolSeleccionado;

  @override
  void initState() {
    super.initState();
    _rolSeleccionado = widget.rolActual;
  }

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
                    Icon(
                      Icons.manage_accounts,
                      color: colorScheme.primary,
                      size: DesignTokens.iconSizeL,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        'Cambiar rol',
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

                // Subtitulo con nombre de usuario
                Text(
                  'Selecciona el nuevo rol para ${widget.nombreUsuario}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingL),

                // Lista de roles
                ...RolOption.roles.map((rol) => _buildRolTile(rol, colorScheme, theme)),

                const SizedBox(height: DesignTokens.spacingL),

                // Mensaje de confirmacion si hay cambio
                if (_rolSeleccionado != widget.rolActual)
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spacingM),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: DesignTokens.iconSizeM,
                        ),
                        const SizedBox(width: DesignTokens.spacingS),
                        Expanded(
                          child: Text(
                            'El cambio de rol se aplicara inmediatamente',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
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
                        label: 'Confirmar',
                        onPressed: _rolSeleccionado != widget.rolActual
                            ? () => widget.onConfirmar(_rolSeleccionado)
                            : null,
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

  Widget _buildRolTile(RolOption rol, ColorScheme colorScheme, ThemeData theme) {
    final isSelected = _rolSeleccionado == rol.value;
    final isCurrentRol = widget.rolActual == rol.value;

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
                      Row(
                        children: [
                          Text(
                            rol.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: DesignTokens.fontWeightSemiBold,
                            ),
                          ),
                          if (isCurrentRol)
                            Container(
                              margin: const EdgeInsets.only(left: DesignTokens.spacingS),
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.spacingS,
                                vertical: DesignTokens.spacingXxs,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                              ),
                              child: Text(
                                'Actual',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
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
