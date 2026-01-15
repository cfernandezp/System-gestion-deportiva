import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/session/session.dart';
import '../theme/design_tokens.dart';
import 'app_button.dart';

/// Variantes de presentacion del boton de logout
enum LogoutButtonVariant {
  /// Boton con texto completo "Cerrar sesion"
  expanded,

  /// Solo icono de logout
  iconOnly,

  /// Item de menu para usar en PopupMenu o Drawer
  menuItem,
}

/// Boton reutilizable para cerrar sesion
/// Implementa HU-004: CA-001 - Opcion de cerrar sesion visible
///
/// Este widget:
/// - Muestra opcion clara para cerrar sesion (CA-001)
/// - Dispara evento de logout al SessionBloc
/// - Muestra dialogo de confirmacion (CA-002)
/// - Redirige a login post-cierre (RN-003)
///
/// Uso:
/// ```dart
/// // En AppBar como IconButton
/// LogoutButton(variant: LogoutButtonVariant.iconOnly)
///
/// // En Drawer o sidebar
/// LogoutButton(variant: LogoutButtonVariant.menuItem)
///
/// // Como boton completo
/// LogoutButton(variant: LogoutButtonVariant.expanded)
/// ```
class LogoutButton extends StatelessWidget {
  const LogoutButton({
    super.key,
    this.variant = LogoutButtonVariant.expanded,
    this.showConfirmDialog = true,
    this.onLogoutComplete,
  });

  /// Variante visual del boton
  final LogoutButtonVariant variant;

  /// Si debe mostrar dialogo de confirmacion antes de cerrar sesion
  /// CA-002: "Cuando confirmo la accion"
  final bool showConfirmDialog;

  /// Callback opcional despues de cerrar sesion exitosamente
  final VoidCallback? onLogoutComplete;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listener: (context, state) {
        if (state is SessionUnauthenticated) {
          // RN-003: Redireccion obligatoria post-cierre
          context.go('/login');
          onLogoutComplete?.call();
        } else if (state is SessionError) {
          // Mostrar error pero aun asi redirigir (ya se cerro sesion local)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(DesignTokens.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
            ),
          );
        }
      },
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    switch (variant) {
      case LogoutButtonVariant.expanded:
        return _buildExpandedButton(context);
      case LogoutButtonVariant.iconOnly:
        return _buildIconButton(context);
      case LogoutButtonVariant.menuItem:
        return _buildMenuItem(context);
    }
  }

  /// Boton expandido con texto
  Widget _buildExpandedButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final isLoading = state is SessionLoggingOut;

        return AppButton(
          label: 'Cerrar sesion',
          icon: Icons.logout,
          variant: AppButtonVariant.secondary,
          isLoading: isLoading,
          loadingLabel: 'Cerrando...',
          onPressed: isLoading ? null : () => _handleLogout(context),
        );
      },
    );
  }

  /// Boton solo icono para AppBar
  Widget _buildIconButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final isLoading = state is SessionLoggingOut;

        if (isLoading) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        return IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesion',
          onPressed: () => _handleLogout(context),
        );
      },
    );
  }

  /// Item de menu para Drawer o PopupMenu
  Widget _buildMenuItem(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final isLoading = state is SessionLoggingOut;
        final theme = Theme.of(context);

        return ListTile(
          leading: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          title: Text(isLoading ? 'Cerrando...' : 'Cerrar sesion'),
          textColor: theme.colorScheme.error,
          iconColor: theme.colorScheme.error,
          enabled: !isLoading,
          onTap: isLoading ? null : () => _handleLogout(context),
        );
      },
    );
  }

  /// Maneja el proceso de logout
  /// CA-002: Mostrar confirmacion antes de cerrar
  Future<void> _handleLogout(BuildContext context) async {
    if (showConfirmDialog) {
      final confirmed = await _showConfirmDialog(context);
      if (confirmed != true) return;
    }

    if (context.mounted) {
      context.read<SessionBloc>().add(const LogoutEvent());
    }
  }

  /// Dialogo de confirmacion de cierre de sesion
  /// CA-002: "Cuando confirmo la accion"
  Future<bool?> _showConfirmDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: colorScheme.error),
            const SizedBox(width: DesignTokens.spacingS),
            const Text('Cerrar sesion'),
          ],
        ),
        content: const Text(
          'Estas seguro de que deseas cerrar tu sesion? '
          'Deberas iniciar sesion nuevamente para acceder al sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Cerrar sesion'),
          ),
        ],
      ),
    );
  }
}
