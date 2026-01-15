import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/bloc/session/session.dart';

/// Pagina principal post-login
/// Implementa HU-004: Cierre de Sesion
///
/// Criterios de Aceptacion:
/// - CA-001: Opcion de cerrar sesion visible -> LogoutButton en AppBar
/// - CA-002: Cierre de sesion exitoso -> Redireccion a login
/// - CA-003: Acceso denegado post-logout -> Guard en router
///
/// Reglas de Negocio:
/// - RN-001: Disponibilidad de opcion de cierre -> Siempre visible en AppBar
/// - RN-003: Redireccion obligatoria post-cierre -> BlocListener maneja
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listener: (context, state) {
        // RN-003: Redireccion obligatoria post-cierre
        if (state is SessionUnauthenticated) {
          context.go('/login');
        }
      },
      child: const _HomePageContent(),
    );
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < DesignTokens.breakpointMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Deportiva'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          // CA-001: Opcion de cerrar sesion visible en AppBar
          // RN-001: Disponibilidad de la opcion de cierre
          const LogoutButton(variant: LogoutButtonVariant.iconOnly),
          const SizedBox(width: DesignTokens.spacingS),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header de bienvenida con nombre y rol
                  _buildWelcomeHeader(context),
                  const SizedBox(height: DesignTokens.spacingXl),

                  // Accesos rapidos segun rol
                  _buildQuickAccess(context, isMobile),
                  const SizedBox(height: DesignTokens.spacingXl),

                  // Seccion de cierre de sesion alternativo
                  _buildLogoutSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header de bienvenida con nombre y rol del usuario
  Widget _buildWelcomeHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        String nombreCompleto = 'Usuario';
        String email = '';
        String rol = 'jugador';

        if (state is SessionAuthenticated) {
          nombreCompleto = state.nombreCompleto.isNotEmpty
              ? state.nombreCompleto
              : 'Usuario';
          email = state.email;
          rol = state.rol;
        }

        return AppCard(
          variant: AppCardVariant.elevated,
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: Row(
            children: [
              // Avatar con inicial
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: DesignTokens.primaryGradient,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Center(
                  child: Text(
                    nombreCompleto.isNotEmpty
                        ? nombreCompleto[0].toUpperCase()
                        : 'U',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spacingM),

              // Informacion del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido,',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXxs),
                    Text(
                      nombreCompleto,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DesignTokens.spacingXs),
                    Row(
                      children: [
                        // Badge de rol
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spacingS,
                            vertical: DesignTokens.spacingXxs,
                          ),
                          decoration: BoxDecoration(
                            color: _getRolColor(rol).withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusFull),
                            border: Border.all(
                              color: _getRolColor(rol).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getRolIcon(rol),
                                size: DesignTokens.iconSizeS,
                                color: _getRolColor(rol),
                              ),
                              const SizedBox(width: DesignTokens.spacingXxs),
                              Text(
                                _formatRol(rol),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _getRolColor(rol),
                                  fontWeight: DesignTokens.fontWeightSemiBold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.spacingXs),
                      Text(
                        email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Accesos rapidos segun el rol del usuario
  Widget _buildQuickAccess(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);

    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        String rol = 'jugador';
        if (state is SessionAuthenticated) {
          rol = state.rol;
        }

        final accesos = _getAccesosPorRol(rol);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accesos rapidos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            LayoutBuilder(
              builder: (context, constraints) {
                // Grid adaptativo segun ancho disponible
                final crossAxisCount = isMobile ? 2 : 3;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: DesignTokens.spacingM,
                    mainAxisSpacing: DesignTokens.spacingM,
                    childAspectRatio: isMobile ? 1.2 : 1.5,
                  ),
                  itemCount: accesos.length,
                  itemBuilder: (context, index) {
                    final acceso = accesos[index];
                    return _QuickAccessCard(
                      title: acceso.title,
                      icon: acceso.icon,
                      color: acceso.color,
                      route: acceso.route,
                      enabled: acceso.enabled,
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Seccion con boton de logout expandido
  /// CA-001: Opcion alternativa de cerrar sesion
  Widget _buildLogoutSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                size: DesignTokens.iconSizeM,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Text(
                  'Sesion activa',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Para proteger tu cuenta, cierra sesion cuando termines de usar el sistema.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          // CA-001: Boton expandido de logout
          const LogoutButton(variant: LogoutButtonVariant.expanded),
        ],
      ),
    );
  }

  /// Obtiene accesos rapidos segun el rol del usuario
  List<_QuickAccessItem> _getAccesosPorRol(String rol) {
    // E002-HU-001: Mi Perfil ahora habilitado
    final List<_QuickAccessItem> accesosComunes = [
      _QuickAccessItem(
        title: 'Mi Perfil',
        icon: Icons.person_outline,
        color: DesignTokens.primaryColor,
        route: '/perfil',
        enabled: true, // E002-HU-001: Ver Perfil Propio
      ),
    ];

    switch (rol.toLowerCase()) {
      case 'administrador':
        return [
          _QuickAccessItem(
            title: 'Usuarios',
            icon: Icons.people_outline,
            color: DesignTokens.secondaryColor,
            route: '/admin/usuarios',
            enabled: true,
          ),
          _QuickAccessItem(
            title: 'Equipos',
            icon: Icons.groups_outlined,
            color: DesignTokens.accentColor,
            route: '/equipos',
            enabled: false,
          ),
          _QuickAccessItem(
            title: 'Torneos',
            icon: Icons.emoji_events_outlined,
            color: DesignTokens.primaryColor,
            route: '/torneos',
            enabled: false,
          ),
          ...accesosComunes,
        ];

      case 'entrenador':
        return [
          _QuickAccessItem(
            title: 'Mi Equipo',
            icon: Icons.groups_outlined,
            color: DesignTokens.primaryColor,
            route: '/mi-equipo',
            enabled: false,
          ),
          _QuickAccessItem(
            title: 'Partidos',
            icon: Icons.sports_soccer,
            color: DesignTokens.secondaryColor,
            route: '/partidos',
            enabled: false,
          ),
          ...accesosComunes,
        ];

      case 'arbitro':
        return [
          _QuickAccessItem(
            title: 'Mis Partidos',
            icon: Icons.sports,
            color: DesignTokens.accentColor,
            route: '/mis-partidos',
            enabled: false,
          ),
          _QuickAccessItem(
            title: 'Calendario',
            icon: Icons.calendar_today_outlined,
            color: DesignTokens.secondaryColor,
            route: '/calendario',
            enabled: false,
          ),
          ...accesosComunes,
        ];

      case 'jugador':
      default:
        return [
          _QuickAccessItem(
            title: 'Mis Partidos',
            icon: Icons.sports_soccer,
            color: DesignTokens.primaryColor,
            route: '/mis-partidos',
            enabled: false,
          ),
          _QuickAccessItem(
            title: 'Mi Equipo',
            icon: Icons.groups_outlined,
            color: DesignTokens.secondaryColor,
            route: '/mi-equipo',
            enabled: false,
          ),
          _QuickAccessItem(
            title: 'Estadisticas',
            icon: Icons.analytics_outlined,
            color: DesignTokens.accentColor,
            route: '/estadisticas',
            enabled: false,
          ),
          ...accesosComunes,
        ];
    }
  }

  /// Obtiene el color asociado a un rol
  Color _getRolColor(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return DesignTokens.secondaryColor;
      case 'entrenador':
        return DesignTokens.primaryColor;
      case 'arbitro':
        return DesignTokens.accentColor;
      case 'jugador':
      default:
        return DesignTokens.primaryColor;
    }
  }

  /// Obtiene el icono asociado a un rol
  IconData _getRolIcon(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return Icons.admin_panel_settings;
      case 'entrenador':
        return Icons.sports;
      case 'arbitro':
        return Icons.sports_score;
      case 'jugador':
      default:
        return Icons.sports_soccer;
    }
  }

  /// Formatea el nombre del rol para mostrar
  String _formatRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return 'Administrador';
      case 'entrenador':
        return 'Entrenador';
      case 'arbitro':
        return 'Arbitro';
      case 'jugador':
        return 'Jugador';
      default:
        return rol;
    }
  }
}

/// Card de acceso rapido
class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    required this.enabled,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => context.go(route) : null,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: enabled
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled
                      ? color.withValues(alpha: 0.1)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(
                  icon,
                  color: enabled ? color : colorScheme.onSurfaceVariant,
                  size: DesignTokens.iconSizeL,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                  color:
                      enabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!enabled) ...[
                const SizedBox(height: DesignTokens.spacingXxs),
                Text(
                  'Proximamente',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Modelo de item de acceso rapido
class _QuickAccessItem {
  const _QuickAccessItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    required this.enabled,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final bool enabled;
}
