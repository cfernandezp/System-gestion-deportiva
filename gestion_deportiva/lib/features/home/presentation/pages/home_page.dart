import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/bloc/session/session.dart';
import '../../../settings/presentation/bloc/theme/theme.dart';
// E001-HU-003: Contexto del grupo actual
import '../../../grupos/presentation/cubit/grupo_actual_cubit.dart';
// E004-HU-008: Mi Actividad en Vivo
import '../../../mi_actividad/presentation/bloc/mi_actividad/mi_actividad_bloc.dart';
import '../../../mi_actividad/presentation/bloc/mi_actividad/mi_actividad_event.dart';
import '../../../mi_actividad/presentation/bloc/mi_actividad/mi_actividad_state.dart';
import '../../../mi_actividad/presentation/widgets/mi_actividad_vivo_widget.dart';
import '../../../upgrade/presentation/models/upgrade_reason.dart';

/// Pagina principal post-login
/// E000-HU-004: ResponsiveLayout mobile + tablet
/// CA-003: Home layout 2 columnas en tablet
/// CA-005: NavigationRail en tablet
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
        mobile: const _MobileHomeView(),
        tablet: const _TabletHomeView(),
      ),
    );
  }
}

// ============================================
// VISTA MOBILE - App Style (sin cambios, RN-002)
// ============================================

class _MobileHomeView extends StatelessWidget {
  const _MobileHomeView();

  @override
  Widget build(BuildContext context) {
    final grupoActualCubit = sl<GrupoActualCubit>();
    final grupoActual = grupoActualCubit.grupoActual;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Gestion Deportiva'),
            if (grupoActual != null)
              Text(
                grupoActual.nombre,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          _ThemeToggleButton(),
          if (grupoActualCubit.tieneMultiplesGrupos)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Cambiar grupo',
              onPressed: () => context.go('/seleccionar-grupo', extra: true),
            ),
          const LogoutButton(variant: LogoutButtonVariant.iconOnly),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MiActividadVivoWidget(),
              _buildWelcomeCard(context),
              const SizedBox(height: DesignTokens.spacingL),
              _buildQuickAccessSection(context, crossAxisCount: 2),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}

// ============================================
// VISTA TABLET - CA-003, CA-005
// NavigationRail lateral + 2 columnas
// ============================================

class _TabletHomeView extends StatelessWidget {
  const _TabletHomeView();

  @override
  Widget build(BuildContext context) {
    final grupoActualCubit = sl<GrupoActualCubit>();
    final grupoActual = grupoActualCubit.grupoActual;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Gestion Deportiva'),
            if (grupoActual != null)
              Text(
                grupoActual.nombre,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          _ThemeToggleButton(),
          if (grupoActualCubit.tieneMultiplesGrupos)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Cambiar grupo',
              onPressed: () => context.go('/seleccionar-grupo', extra: true),
            ),
          const LogoutButton(variant: LogoutButtonVariant.iconOnly),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            // CA-005: NavigationRail lateral en tablet
            _TabletNavigationRail(currentIndex: 0),

            // Contenido principal expandido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MiActividadVivoWidget(),

                    // CA-003: Layout 2 columnas en tablet
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna izquierda: Welcome card
                        Expanded(
                          flex: 1,
                          child: _buildWelcomeCard(context),
                        ),
                        const SizedBox(width: DesignTokens.spacingL),
                        // Columna derecha: Info rapida
                        Expanded(
                          flex: 1,
                          child: _buildInfoCard(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spacingL),

                    // CA-003: Accesos rapidos en grid 3-4 columnas en tablet
                    _buildQuickAccessSection(context, crossAxisCount: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card de informacion del grupo/novedades para tablet
  Widget _buildInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_outlined,
                  size: 20, color: colorScheme.primary),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                'Novedades',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          const Divider(),
          const SizedBox(height: DesignTokens.spacingS),
          _NewsItem(
            icon: Icons.check_circle_outline,
            title: 'Sistema Activo',
            description: 'Autenticacion y grupos funcionando correctamente.',
            color: DesignTokens.successColor,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          _NewsItem(
            icon: Icons.build_outlined,
            title: 'En Desarrollo',
            description: 'Torneos y estadisticas proximamente.',
            color: DesignTokens.accentColor,
          ),
        ],
      ),
    );
  }
}

// ============================================
// CA-005/RN-004: NavigationRail para tablet
// Reemplaza BottomNavigationBar en tablet
// ============================================

class _TabletNavigationRail extends StatelessWidget {
  final int currentIndex;

  const _TabletNavigationRail({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        String userRole = 'jugador';
        if (state is SessionAuthenticated) {
          userRole = state.rol.toLowerCase();
        }

        final items = AppBottomNavBar.getItemsForRole(userRole);

        return NavigationRail(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            if (index < items.length) {
              context.go(items[index].route);
            }
          },
          labelType: NavigationRailLabelType.all,
          backgroundColor: colorScheme.surface,
          selectedIconTheme: IconThemeData(color: colorScheme.primary),
          selectedLabelTextStyle: TextStyle(
            color: colorScheme.primary,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontSize: DesignTokens.fontSizeXs,
          ),
          unselectedIconTheme: IconThemeData(
            color: colorScheme.onSurfaceVariant,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: DesignTokens.fontSizeXs,
          ),
          leading: Padding(
            padding: const EdgeInsets.only(
              top: DesignTokens.spacingS,
              bottom: DesignTokens.spacingM,
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: DesignTokens.primaryGradient,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: DesignTokens.iconSizeM,
              ),
            ),
          ),
          destinations: items
              .map((item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ))
              .toList(),
        );
      },
    );
  }
}

// ============================================
// WIDGETS COMPARTIDOS
// ============================================

Widget _buildWelcomeCard(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final grupoActual = sl<GrupoActualCubit>().grupoActual;

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

      final planDisplay = grupoActual?.planDisplay ?? 'Plan Gratis';
      final esPlanGratis = grupoActual?.esPlanGratis ?? true;
      final planColor = esPlanGratis
          ? colorScheme.onSurfaceVariant
          : DesignTokens.accentColor;

      return AppCard(
        variant: AppCardVariant.elevated,
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: _getRolGradient(rol),
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
                  Wrap(
                    spacing: DesignTokens.spacingS,
                    runSpacing: DesignTokens.spacingXxs,
                    children: [
                      _RolBadge(rol: rol),
                      GestureDetector(
                        onTap: () => context.push(
                          '/upgrade',
                          extra: const UpgradeReason.explorar(),
                        ),
                        child: _PlanBadge(
                          planDisplay: planDisplay,
                          esPlanGratis: esPlanGratis,
                          planColor: planColor,
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

Widget _buildQuickAccessSection(BuildContext context,
    {required int crossAxisCount}) {
  final theme = Theme.of(context);

  return BlocBuilder<SessionBloc, SessionState>(
    builder: (context, state) {
      String rol = 'jugador';
      if (state is SessionAuthenticated) {
        rol = state.rol;
      }

      return BlocProvider(
        create: (context) =>
            sl<MiActividadBloc>()..add(const CargarMiActividadEvent()),
        child: BlocBuilder<MiActividadBloc, MiActividadState>(
          builder: (context, miActividadState) {
            bool tieneEquipo = false;
            if (miActividadState is MiActividadLoaded &&
                miActividadState.actividad.miEquipo != null) {
              tieneEquipo = true;
            }

            final accesos = _getAccesosPorRol(rol, tieneEquipo: tieneEquipo);

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
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: DesignTokens.spacingM,
                    mainAxisSpacing: DesignTokens.spacingM,
                    childAspectRatio: crossAxisCount <= 2 ? 1.2 : 1.3,
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
        ),
      );
    },
  );
}

// ============================================
// FUNCIONES AUXILIARES
// ============================================

List<_QuickAccessItem> _getAccesosPorRol(String rol,
    {bool tieneEquipo = false}) {
  final List<_QuickAccessItem> accesosComunes = [
    _QuickAccessItem(
      title: 'Mi Perfil',
      description: 'Ver y editar mi informacion personal',
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
          title: 'Mi Actividad',
          description: 'Ver mi actividad en vivo',
          icon: Icons.sports_soccer,
          color: DesignTokens.primaryColor,
          route: '/mi-actividad',
          enabled: true,
        ),
        _QuickAccessItem(
          title: 'Jugadores',
          description: 'Ver miembros del grupo',
          icon: Icons.people_outline,
          color: DesignTokens.secondaryColor,
          route: '/jugadores',
          enabled: true,
        ),
        _QuickAccessItem(
          title: 'Mis Grupos',
          description: 'Ver y acceder a mis grupos',
          icon: Icons.groups_outlined,
          color: DesignTokens.accentColor,
          route: '/mis-grupos',
          enabled: true,
        ),
        _QuickAccessItem(
          title: 'Torneos',
          description: 'Crear y gestionar torneos',
          icon: Icons.emoji_events_outlined,
          color: const Color(0xFF8B5CF6),
          route: '/torneos',
          enabled: false,
        ),
        _QuickAccessItem(
          title: 'Reportes',
          description: 'Ver estadisticas y reportes',
          icon: Icons.analytics_outlined,
          color: const Color(0xFFEC4899),
          route: '/reportes',
          enabled: false,
        ),
        ...accesosComunes,
      ];

    case 'jugador':
    default:
      return [
        _QuickAccessItem(
          title: 'Mi Actividad',
          description: 'Ver mi actividad en vivo',
          icon: Icons.sports_soccer,
          color: DesignTokens.primaryColor,
          route: '/mi-actividad',
          enabled: true,
        ),
        _QuickAccessItem(
          title: 'Mi Equipo',
          description: tieneEquipo
              ? 'Ver tu equipo asignado'
              : 'Ver informacion de mi equipo',
          icon: Icons.groups_outlined,
          color: DesignTokens.secondaryColor,
          route: '/mi-actividad',
          enabled: tieneEquipo,
        ),
        _QuickAccessItem(
          title: 'Estadisticas',
          description: 'Ver mi rendimiento y estadisticas',
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
    case 'entrenador':
      return DesignTokens.accentColor;
    case 'arbitro':
      return const Color(0xFF8B5CF6);
    case 'jugador':
    default:
      return DesignTokens.primaryColor;
  }
}

LinearGradient _getRolGradient(String rol) {
  switch (rol.toLowerCase()) {
    case 'administrador':
    case 'admin':
      return DesignTokens.secondaryGradient;
    case 'entrenador':
      return DesignTokens.accentGradient;
    case 'jugador':
    default:
      return DesignTokens.primaryGradient;
  }
}

IconData _getRolIcon(String rol) {
  switch (rol.toLowerCase()) {
    case 'administrador':
    case 'admin':
      return Icons.admin_panel_settings;
    case 'entrenador':
      return Icons.sports;
    case 'arbitro':
      return Icons.gavel;
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

// ============================================
// WIDGETS DE UI
// ============================================

class _RolBadge extends StatelessWidget {
  final String rol;
  const _RolBadge({required this.rol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rolColor = _getRolColor(rol);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: rolColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(color: rolColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getRolIcon(rol), size: DesignTokens.iconSizeS, color: rolColor),
          const SizedBox(width: DesignTokens.spacingXxs),
          Text(
            _formatRol(rol),
            style: theme.textTheme.labelSmall?.copyWith(
              color: rolColor,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String planDisplay;
  final bool esPlanGratis;
  final Color planColor;

  const _PlanBadge({
    required this.planDisplay,
    required this.esPlanGratis,
    required this.planColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: planColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(color: planColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esPlanGratis ? Icons.star_border : Icons.star,
            size: DesignTokens.iconSizeS,
            color: planColor,
          ),
          const SizedBox(width: DesignTokens.spacingXxs),
          Text(
            planDisplay,
            style: theme.textTheme.labelSmall?.copyWith(
              color: planColor,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}

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
                  color: enabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
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

class _NewsItem extends StatelessWidget {
  const _NewsItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: DesignTokens.iconSizeM, color: color),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXxs),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================
// TOGGLE DE TEMA
// ============================================

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeBloc>().state.themeMode;

    return IconButton(
      icon: Icon(_themeIcon(themeMode)),
      tooltip: _themeTooltip(themeMode),
      onPressed: () {
        final nextMode = _nextThemeMode(themeMode);
        context.read<ThemeBloc>().add(ChangeThemeEvent(nextMode));
      },
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  String _themeTooltip(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Tema: Sistema';
      case ThemeMode.light:
        return 'Tema: Claro';
      case ThemeMode.dark:
        return 'Tema: Oscuro';
    }
  }

  ThemeMode _nextThemeMode(ThemeMode current) {
    switch (current) {
      case ThemeMode.system:
        return ThemeMode.light;
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.system;
    }
  }
}

// ============================================
// MODELO DE DATOS
// ============================================

class _QuickAccessItem {
  const _QuickAccessItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
    required this.enabled,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  final bool enabled;
}
