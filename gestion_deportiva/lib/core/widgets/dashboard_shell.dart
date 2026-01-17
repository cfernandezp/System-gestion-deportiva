import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';
import '../../features/auth/presentation/bloc/session/session.dart';

/// Item de navegacion del sidebar
class NavItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String route;
  final bool enabled;
  final List<String>? roles; // Roles que pueden ver este item

  const NavItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.route,
    this.enabled = true,
    this.roles,
  });
}

/// Shell de dashboard para tablet/desktop
/// Incluye sidebar de navegacion y header
class DashboardShell extends StatefulWidget {
  /// Ruta actual para resaltar en el sidebar
  final String currentRoute;

  /// Titulo de la pagina actual
  final String title;

  /// Breadcrumbs opcionales
  final List<String>? breadcrumbs;

  /// Acciones adicionales en el header
  final List<Widget>? actions;

  /// Contenido principal
  final Widget child;

  /// Si el sidebar debe estar colapsado por defecto
  final bool collapsedByDefault;

  const DashboardShell({
    super.key,
    required this.currentRoute,
    required this.title,
    this.breadcrumbs,
    this.actions,
    required this.child,
    this.collapsedByDefault = false,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  late bool _isCollapsed;

  // Items de navegacion del sidebar
  static const List<NavItem> _navItems = [
    NavItem(
      label: 'Inicio',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: '/',
    ),
    NavItem(
      label: 'Mi Perfil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: '/perfil',
    ),
    // E002-HU-003: Lista de Jugadores
    NavItem(
      label: 'Jugadores',
      icon: Icons.group_outlined,
      selectedIcon: Icons.group,
      route: '/jugadores',
    ),
    // E003-HU-002: Inscribirse a Fecha (todos los usuarios)
    NavItem(
      label: 'Pichangas',
      icon: Icons.sports_soccer_outlined,
      selectedIcon: Icons.sports_soccer,
      route: '/fechas',
    ),
    NavItem(
      label: 'Usuarios',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: '/admin/usuarios',
      roles: ['admin', 'administrador'],
    ),
    // E003-HU-001: Crear Fecha (solo admin)
    NavItem(
      label: 'Crear Fecha',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      route: '/fechas/crear',
      roles: ['admin', 'administrador'],
    ),
    NavItem(
      label: 'Equipos',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      route: '/equipos',
      enabled: false,
    ),
    NavItem(
      label: 'Torneos',
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events,
      route: '/torneos',
      enabled: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.collapsedByDefault;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Auto-colapsar en tablet
    final isTablet = screenWidth < 1024;
    final effectiveCollapsed = isTablet || _isCollapsed;
    final sidebarWidth = effectiveCollapsed ? 72.0 : 260.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(
            context,
            colorScheme,
            textTheme,
            sidebarWidth,
            effectiveCollapsed,
            isTablet,
          ),

          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Header
                _buildHeader(context, colorScheme, textTheme),

                // Breadcrumbs
                if (widget.breadcrumbs != null && widget.breadcrumbs!.isNotEmpty)
                  _buildBreadcrumbs(context, colorScheme, textTheme),

                // Contenido
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    double width,
    bool collapsed,
    bool isTablet,
  ) {
    return AnimatedContainer(
      duration: DesignTokens.animNormal,
      curve: DesignTokens.animCurve,
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo/Brand
          _buildBrand(context, colorScheme, textTheme, collapsed),

          const SizedBox(height: DesignTokens.spacingM),

          // Nav items
          Expanded(
            child: BlocBuilder<SessionBloc, SessionState>(
              builder: (context, state) {
                String userRole = 'jugador';
                if (state is SessionAuthenticated) {
                  userRole = state.rol.toLowerCase();
                }

                return ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: collapsed ? DesignTokens.spacingS : DesignTokens.spacingM,
                  ),
                  children: _navItems
                      .where((item) => _canShowItem(item, userRole))
                      .map((item) => _buildNavItem(
                            context,
                            colorScheme,
                            textTheme,
                            item,
                            collapsed,
                          ))
                      .toList(),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Toggle collapse button (solo en desktop)
          if (!isTablet)
            _buildCollapseButton(context, colorScheme, collapsed),

          // Logout
          _buildLogoutButton(context, colorScheme, textTheme, collapsed),

          const SizedBox(height: DesignTokens.spacingM),
        ],
      ),
    );
  }

  bool _canShowItem(NavItem item, String userRole) {
    if (item.roles == null) return true;
    return item.roles!.contains(userRole);
  }

  Widget _buildBrand(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool collapsed,
  ) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? DesignTokens.spacingS : DesignTokens.spacingM,
      ),
      child: Row(
        children: [
          Container(
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
          if (!collapsed) ...[
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                'Gestion Deportiva',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    NavItem item,
    bool collapsed,
  ) {
    final isSelected = widget.currentRoute == item.route;
    final effectiveIcon = isSelected ? (item.selectedIcon ?? item.icon) : item.icon;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingXs),
      child: Tooltip(
        message: collapsed ? item.label : '',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: InkWell(
            onTap: item.enabled ? () => context.go(item.route) : null,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: AnimatedContainer(
              duration: DesignTokens.animFast,
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? DesignTokens.spacingM : DesignTokens.spacingM,
                vertical: DesignTokens.spacingS + 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: isSelected
                    ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment:
                    collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Icon(
                    effectiveIcon,
                    color: !item.enabled
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                    size: DesignTokens.iconSizeM,
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: DesignTokens.spacingM),
                    Expanded(
                      child: Text(
                        item.label,
                        style: textTheme.bodyMedium?.copyWith(
                          color: !item.enabled
                              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                              : isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                          fontWeight: isSelected
                              ? DesignTokens.fontWeightSemiBold
                              : DesignTokens.fontWeightRegular,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!item.enabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingXs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                        ),
                        child: Text(
                          'Pronto',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton(
    BuildContext context,
    ColorScheme colorScheme,
    bool collapsed,
  ) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      child: IconButton(
        onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
        icon: Icon(
          collapsed ? Icons.chevron_right : Icons.chevron_left,
          color: colorScheme.onSurfaceVariant,
        ),
        tooltip: collapsed ? 'Expandir menu' : 'Colapsar menu',
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool collapsed,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? DesignTokens.spacingS : DesignTokens.spacingM,
      ),
      child: Tooltip(
        message: collapsed ? 'Cerrar sesion' : '',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: InkWell(
            onTap: () {
              context.read<SessionBloc>().add(const LogoutEvent());
            },
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? DesignTokens.spacingM : DesignTokens.spacingM,
                vertical: DesignTokens.spacingS + 4,
              ),
              child: Row(
                mainAxisAlignment:
                    collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.logout,
                    color: colorScheme.error,
                    size: DesignTokens.iconSizeM,
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: DesignTokens.spacingM),
                    Text(
                      'Cerrar sesion',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Titulo
          Text(
            widget.title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),

          const Spacer(),

          // Acciones personalizadas
          if (widget.actions != null) ...widget.actions!,

          const SizedBox(width: DesignTokens.spacingM),

          // Usuario
          BlocBuilder<SessionBloc, SessionState>(
            builder: (context, state) {
              String nombre = 'Usuario';
              String email = '';

              if (state is SessionAuthenticated) {
                nombre = state.nombreCompleto.isNotEmpty
                    ? state.nombreCompleto
                    : 'Usuario';
                email = state.email;
              }

              return Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        nombre,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: DesignTokens.primaryGradient,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                    ),
                    child: Center(
                      child: Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < widget.breadcrumbs!.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingXs),
                child: Icon(
                  Icons.chevron_right,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              widget.breadcrumbs![i],
              style: textTheme.bodySmall?.copyWith(
                color: i == widget.breadcrumbs!.length - 1
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
                fontWeight: i == widget.breadcrumbs!.length - 1
                    ? DesignTokens.fontWeightMedium
                    : DesignTokens.fontWeightRegular,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
