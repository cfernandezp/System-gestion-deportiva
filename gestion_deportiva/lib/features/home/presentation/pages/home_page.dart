import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/bloc/session/session.dart';

/// Pagina principal post-login
/// Implementa HU-004: Cierre de Sesion
/// Usa ResponsiveLayout: Mobile App Style + Desktop Dashboard Style
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listener: (context, state) {
        if (state is SessionUnauthenticated) {
          context.go('/login');
        }
      },
      child: ResponsiveLayout(
        mobileBody: const _MobileHomeView(),
        desktopBody: const _DesktopHomeView(),
      ),
    );
  }
}

// ============================================
// VISTA MOBILE - App Style
// ============================================

class _MobileHomeView extends StatelessWidget {
  const _MobileHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Deportiva'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: DesignTokens.spacingL),
              _buildQuickAccessSection(context, isMobile: true),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}

// ============================================
// VISTA DESKTOP - Dashboard Style
// Layout: Panel usuario (300px) + Contenido expandido
// ============================================

class _DesktopHomeView extends StatelessWidget {
  const _DesktopHomeView();

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/',
      title: 'Inicio',
      breadcrumbs: const ['Inicio'],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel izquierdo fijo - Info del usuario (300px)
            SizedBox(
              width: 300,
              child: _buildUserPanel(context),
            ),
            const SizedBox(width: DesignTokens.spacingL),

            // Panel derecho expandido - Accesos y contenido
            Expanded(
              child: _buildMainContent(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Panel lateral con info del usuario
  Widget _buildUserPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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

        return Container(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              // Avatar grande
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: DesignTokens.primaryGradient,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Center(
                  child: Text(
                    nombreCompleto.isNotEmpty
                        ? nombreCompleto[0].toUpperCase()
                        : 'U',
                    style: textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingM),

              // Bienvenida
              Text(
                'Bienvenido,',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXxs),

              // Nombre
              Text(
                nombreCompleto,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: DesignTokens.spacingM),

              // Badge de rol
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: _getRolColor(rol).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
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
                    const SizedBox(width: DesignTokens.spacingXs),
                    Text(
                      _formatRol(rol),
                      style: textTheme.labelLarge?.copyWith(
                        color: _getRolColor(rol),
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                  ],
                ),
              ),

              if (email.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.spacingL),
                const Divider(),
                const SizedBox(height: DesignTokens.spacingM),

                // Email con icono
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        size: DesignTokens.iconSizeS,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Correo',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            email,
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: DesignTokens.fontWeightMedium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: DesignTokens.spacingL),

              // Boton ver perfil
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/perfil'),
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Ver mi perfil'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Contenido principal expandido
  Widget _buildMainContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            // Titulo de seccion
            Text(
              'Accesos rapidos',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              'Accede rapidamente a las funciones mas utilizadas',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingL),

            // Grid de accesos - 3 columnas en desktop
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: DesignTokens.spacingM,
                mainAxisSpacing: DesignTokens.spacingM,
                childAspectRatio: 1.4,
              ),
              itemCount: accesos.length,
              itemBuilder: (context, index) {
                final acceso = accesos[index];
                return _DesktopQuickAccessCard(
                  title: acceso.title,
                  icon: acceso.icon,
                  color: acceso.color,
                  route: acceso.route,
                  enabled: acceso.enabled,
                );
              },
            ),

            const SizedBox(height: DesignTokens.spacingXl),

            // Card de estadisticas o info adicional
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.spacingL),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: DesignTokens.iconSizeM,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: DesignTokens.spacingS),
                      Text(
                        'Informacion del Sistema',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacingM),
                  const Divider(),
                  const SizedBox(height: DesignTokens.spacingM),
                  Text(
                    'Bienvenido al sistema de gestion deportiva. '
                    'Desde aqui puedes acceder a todas las funciones '
                    'disponibles para tu rol.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Card de acceso rapido mejorada para desktop
class _DesktopQuickAccessCard extends StatelessWidget {
  const _DesktopQuickAccessCard({
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
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          decoration: BoxDecoration(
            color: enabled
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant,
              width: enabled ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: enabled
                      ? color.withValues(alpha: 0.1)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(
                  icon,
                  color: enabled ? color : colorScheme.onSurfaceVariant,
                  size: DesignTokens.iconSizeXl,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: enabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!enabled) ...[
                const SizedBox(height: DesignTokens.spacingXs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Text(
                    'Proximamente',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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

// ============================================
// WIDGETS COMPARTIDOS
// ============================================

Widget _buildWelcomeCard(BuildContext context) {
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
            // Avatar
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

            // Info
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

Widget _buildQuickAccessSection(BuildContext context, {required bool isMobile}) {
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 4,
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
          ),
        ],
      );
    },
  );
}

/// Obtiene accesos rapidos segun el rol del usuario
List<_QuickAccessItem> _getAccesosPorRol(String rol) {
  final List<_QuickAccessItem> accesosComunes = [
    _QuickAccessItem(
      title: 'Mi Perfil',
      icon: Icons.person_outline,
      color: DesignTokens.primaryColor,
      route: '/perfil',
      enabled: true,
    ),
  ];

  switch (rol.toLowerCase()) {
    case 'administrador':
    case 'admin':
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

Color _getRolColor(String rol) {
  switch (rol.toLowerCase()) {
    case 'administrador':
    case 'admin':
      return DesignTokens.secondaryColor;
    case 'jugador':
    default:
      return DesignTokens.primaryColor;
  }
}

IconData _getRolIcon(String rol) {
  switch (rol.toLowerCase()) {
    case 'administrador':
    case 'admin':
      return Icons.admin_panel_settings;
    case 'jugador':
    default:
      return Icons.sports_soccer;
  }
}

String _formatRol(String rol) {
  switch (rol.toLowerCase()) {
    case 'administrador':
    case 'admin':
      return 'Administrador';
    case 'jugador':
      return 'Jugador';
    default:
      return rol;
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
