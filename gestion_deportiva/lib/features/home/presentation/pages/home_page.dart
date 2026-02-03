import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/bloc/session/session.dart';
// E004-HU-008: Mi Actividad en Vivo
import '../../../mi_actividad/data/models/mi_equipo_actividad_model.dart';
import '../../../mi_actividad/presentation/bloc/mi_actividad/mi_actividad_bloc.dart';
import '../../../mi_actividad/presentation/bloc/mi_actividad/mi_actividad_event.dart';
import '../../../mi_actividad/presentation/bloc/mi_actividad/mi_actividad_state.dart';
import '../../../mi_actividad/presentation/widgets/mi_actividad_vivo_widget.dart';

/// Pagina principal post-login - Dashboard CRM Moderno
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
// VISTA MOBILE - App Style Mejorado
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
              // CA-001, RN-007: Widget de Mi Actividad en Vivo (prominente, arriba)
              const MiActividadVivoWidget(),
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
// VISTA DESKTOP - Dashboard CRM Style
// Layout: Panel usuario (320px) + Contenido principal (expandido)
// ============================================

class _DesktopHomeView extends StatelessWidget {
  const _DesktopHomeView();

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/',
      title: 'Dashboard',
      breadcrumbs: const ['Inicio', 'Dashboard'],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel izquierdo fijo - Perfil del usuario (320px)
            SizedBox(
              width: 320,
              child: _UserProfilePanel(),
            ),
            const SizedBox(width: DesignTokens.spacingL),

            // Panel derecho expandido - Contenido principal
            Expanded(
              child: _MainDashboardContent(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// PANEL DE PERFIL DE USUARIO (320px)
// ============================================

class _UserProfilePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: DesignTokens.shadowSm,
          ),
          child: Column(
            children: [
              // Header con gradiente
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DesignTokens.spacingL),
                decoration: BoxDecoration(
                  gradient: _getRolGradient(rol),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(DesignTokens.radiusL),
                    topRight: Radius.circular(DesignTokens.radiusL),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar grande centrado
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          nombreCompleto.isNotEmpty
                              ? nombreCompleto[0].toUpperCase()
                              : 'U',
                          style: textTheme.displaySmall?.copyWith(
                            color: _getRolColor(rol),
                            fontWeight: DesignTokens.fontWeightBold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingM),

                    // Nombre del usuario
                    Text(
                      nombreCompleto,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: DesignTokens.fontWeightBold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DesignTokens.spacingS),

                    // Badge de rol
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingM,
                        vertical: DesignTokens.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRolIcon(rol),
                            size: DesignTokens.iconSizeS,
                            color: Colors.white,
                          ),
                          const SizedBox(width: DesignTokens.spacingXs),
                          Text(
                            _formatRol(rol),
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: DesignTokens.fontWeightSemiBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido del panel
              Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingL),
                child: Column(
                  children: [
                    // Email con icono
                    if (email.isNotEmpty) ...[
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Correo electronico',
                        value: email,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: DesignTokens.spacingM),
                    ],

                    // Estado de cuenta
                    _InfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Estado de cuenta',
                      value: 'Activo',
                      color: DesignTokens.successColor,
                    ),

                    const SizedBox(height: DesignTokens.spacingL),
                    const Divider(),
                    const SizedBox(height: DesignTokens.spacingL),

                    // Boton ver perfil
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go('/perfil'),
                        icon: const Icon(Icons.person_outline, size: 18),
                        label: const Text('Ver mi perfil'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: DesignTokens.spacingM,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingS),

                    // Boton cerrar sesion
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<SessionBloc>().add(const LogoutEvent());
                        },
                        icon: Icon(
                          Icons.logout,
                          size: 18,
                          color: DesignTokens.errorColor,
                        ),
                        label: Text(
                          'Cerrar sesion',
                          style: TextStyle(color: DesignTokens.errorColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: DesignTokens.spacingM,
                          ),
                          side: BorderSide(
                            color: DesignTokens.errorColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget para mostrar una fila de informacion
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Icon(
            icon,
            size: DesignTokens.iconSizeS + 2,
            color: color,
          ),
        ),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXxs),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================
// CONTENIDO PRINCIPAL DEL DASHBOARD
// ============================================

class _MainDashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        String nombreCompleto = 'Usuario';
        String rol = 'jugador';
        if (state is SessionAuthenticated) {
          nombreCompleto = state.nombreCompleto.isNotEmpty
              ? state.nombreCompleto
              : 'Usuario';
          rol = state.rol;
        }

        final isAdmin = rol.toLowerCase() == 'admin' || rol.toLowerCase() == 'administrador';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con titulo y bienvenida
            _DashboardHeader(
              nombreCompleto: nombreCompleto,
              rol: rol,
            ),

            const SizedBox(height: DesignTokens.spacingL),

            // Metricas rapidas (grid 4 columnas)
            _MetricsGrid(isAdmin: isAdmin),

            const SizedBox(height: DesignTokens.spacingXl),

            // Titulo de accesos rapidos
            Row(
              children: [
                Icon(
                  Icons.apps,
                  size: DesignTokens.iconSizeM,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Accesos rapidos',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              'Accede rapidamente a las funciones mas utilizadas',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingL),

            // Grid de accesos rapidos - 3 columnas en desktop
            // Usa BlocProvider para obtener datos del equipo y habilitar "Mi Equipo" dinamicamente
            BlocProvider(
              create: (context) => sl<MiActividadBloc>()..add(const CargarMiActividadEvent()),
              child: BlocBuilder<MiActividadBloc, MiActividadState>(
                builder: (context, miActividadState) {
                  bool tieneEquipo = false;
                  if (miActividadState is MiActividadLoaded &&
                      miActividadState.actividad.miEquipo != null) {
                    tieneEquipo = true;
                  }

                  final accesos = _getAccesosPorRol(rol, tieneEquipo: tieneEquipo);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: DesignTokens.spacingM,
                      mainAxisSpacing: DesignTokens.spacingM,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: accesos.length,
                    itemBuilder: (context, index) {
                      final acceso = accesos[index];
                      return _DesktopQuickAccessCard(
                        title: acceso.title,
                        description: acceso.description,
                        icon: acceso.icon,
                        color: acceso.color,
                        route: acceso.route,
                        enabled: acceso.enabled,
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: DesignTokens.spacingXl),

            // Card de novedades/informacion
            _NewsCard(),
          ],
        );
      },
    );
  }
}

// ============================================
// HEADER DEL DASHBOARD
// ============================================

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.nombreCompleto,
    required this.rol,
  });

  final String nombreCompleto;
  final String rol;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Saludo segun hora del dia
    final hora = DateTime.now().hour;
    String saludo;
    IconData saludoIcon;
    if (hora < 12) {
      saludo = 'Buenos dias';
      saludoIcon = Icons.wb_sunny_outlined;
    } else if (hora < 18) {
      saludo = 'Buenas tardes';
      saludoIcon = Icons.wb_twilight_outlined;
    } else {
      saludo = 'Buenas noches';
      saludoIcon = Icons.nightlight_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      saludoIcon,
                      size: DesignTokens.iconSizeM,
                      color: DesignTokens.accentColor,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Text(
                      saludo,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  nombreCompleto,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingS),
                Text(
                  'Bienvenido al sistema de gestion deportiva',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Icono decorativo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            ),
            child: Icon(
              Icons.sports_soccer,
              size: DesignTokens.iconSizeXl,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// GRID DE METRICAS
// ============================================

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    // Para admin, usar metricas estaticas
    if (isAdmin) {
      return _buildMetricsGridView(context, _getAdminMetrics(), null);
    }

    // Para jugadores, usar BlocProvider para obtener datos del equipo
    return BlocProvider(
      create: (context) => sl<MiActividadBloc>()..add(const CargarMiActividadEvent()),
      child: BlocBuilder<MiActividadBloc, MiActividadState>(
        builder: (context, miActividadState) {
          MiEquipoActividadModel? miEquipo;

          if (miActividadState is MiActividadLoaded &&
              miActividadState.actividad.miEquipo != null) {
            miEquipo = miActividadState.actividad.miEquipo;
          }

          return _buildMetricsGridView(
            context,
            _getPlayerMetrics(miEquipo: miEquipo),
            miEquipo,
          );
        },
      ),
    );
  }

  Widget _buildMetricsGridView(
    BuildContext context,
    List<_MetricData> metrics,
    MiEquipoActividadModel? miEquipo,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: DesignTokens.spacingM,
        mainAxisSpacing: DesignTokens.spacingM,
        childAspectRatio: 1.8,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _MetricCard(
          title: metric.title,
          value: metric.value,
          icon: metric.icon,
          color: metric.color,
          badgeCount: metric.badgeCount,
        );
      },
    );
  }

  List<_MetricData> _getAdminMetrics() {
    return [
      _MetricData(
        title: 'Usuarios registrados',
        value: '--',
        icon: Icons.people_outline,
        color: DesignTokens.primaryColor,
      ),
      _MetricData(
        title: 'Equipos activos',
        value: '--',
        icon: Icons.groups_outlined,
        color: DesignTokens.secondaryColor,
      ),
      _MetricData(
        title: 'Torneos en curso',
        value: '--',
        icon: Icons.emoji_events_outlined,
        color: DesignTokens.accentColor,
      ),
      _MetricData(
        title: 'Solicitudes pendientes',
        value: '--',
        icon: Icons.pending_actions_outlined,
        color: DesignTokens.errorColor,
        badgeCount: 0,
      ),
    ];
  }

  List<_MetricData> _getPlayerMetrics({MiEquipoActividadModel? miEquipo}) {
    // Obtener valor y color del equipo dinamicamente
    final equipoValue = miEquipo?.color.toUpperCase() ?? '--';
    final equipoColor = miEquipo != null
        ? _hexToColor(miEquipo.colorHex)
        : const Color(0xFF8B5CF6);

    return [
      _MetricData(
        title: 'Proximas pichangas',
        value: '--',
        icon: Icons.sports_soccer,
        color: DesignTokens.primaryColor,
      ),
      _MetricData(
        title: 'Mis inscripciones',
        value: '--',
        icon: Icons.how_to_reg_outlined,
        color: DesignTokens.secondaryColor,
      ),
      _MetricData(
        title: 'Partidos jugados',
        value: '--',
        icon: Icons.sports,
        color: DesignTokens.accentColor,
      ),
      _MetricData(
        title: 'Mi equipo',
        value: equipoValue,
        icon: Icons.group_outlined,
        color: equipoColor,
      ),
    ];
  }

  /// Convierte codigo hexadecimal a Color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.badgeCount,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int? badgeCount;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.badgeCount,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Icon(
                  icon,
                  size: DesignTokens.iconSizeM,
                  color: color,
                ),
              ),
              if (badgeCount != null && badgeCount! > 0)
                DotBadge(
                  count: badgeCount,
                  color: DesignTokens.errorColor,
                  child: const SizedBox.shrink(),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXxs),
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================
// CARD DE ACCESO RAPIDO MEJORADA (DESKTOP)
// ============================================

class _DesktopQuickAccessCard extends StatefulWidget {
  const _DesktopQuickAccessCard({
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

  @override
  State<_DesktopQuickAccessCard> createState() => _DesktopQuickAccessCardState();
}

class _DesktopQuickAccessCardState extends State<_DesktopQuickAccessCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: DesignTokens.animFast,
        curve: DesignTokens.animCurve,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered && widget.enabled ? -4.0 : 0.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? () => context.go(widget.route) : null,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spacingL),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? colorScheme.surface
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                border: Border.all(
                  color: widget.enabled
                      ? (_isHovered ? widget.color : widget.color.withValues(alpha: 0.3))
                      : colorScheme.outlineVariant,
                  width: _isHovered && widget.enabled ? 2 : 1,
                ),
                boxShadow: _isHovered && widget.enabled
                    ? DesignTokens.shadowMd
                    : DesignTokens.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: widget.enabled
                              ? widget.color.withValues(alpha: 0.1)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.enabled ? widget.color : colorScheme.onSurfaceVariant,
                          size: DesignTokens.iconSizeL,
                        ),
                      ),
                      if (!widget.enabled)
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
                      if (widget.enabled)
                        Icon(
                          Icons.arrow_forward,
                          size: DesignTokens.iconSizeS,
                          color: _isHovered
                              ? widget.color
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: widget.enabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.spacingXxs),
                  Text(
                    widget.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// CARD DE NOVEDADES
// ============================================

class _NewsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DesignTokens.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Icon(
                  Icons.campaign_outlined,
                  size: DesignTokens.iconSizeM,
                  color: DesignTokens.primaryColor,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Novedades del Sistema',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    Text(
                      'Mantente informado de las ultimas actualizaciones',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          const Divider(),
          const SizedBox(height: DesignTokens.spacingM),

          // Lista de novedades
          _NewsItem(
            icon: Icons.check_circle_outline,
            title: 'Sistema de Autenticacion',
            description: 'El sistema de inicio de sesion y registro esta completamente funcional.',
            color: DesignTokens.successColor,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          _NewsItem(
            icon: Icons.build_outlined,
            title: 'Modulos en Desarrollo',
            description: 'Equipos, torneos y estadisticas estaran disponibles proximamente.',
            color: DesignTokens.accentColor,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          _NewsItem(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Panel de Administracion',
            description: 'Los administradores pueden gestionar usuarios y roles desde el menu.',
            color: DesignTokens.secondaryColor,
          ),
        ],
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
        Icon(
          icon,
          size: DesignTokens.iconSizeM,
          color: color,
        ),
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
// WIDGETS COMPARTIDOS (MOBILE)
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

      // Usar BlocProvider para obtener datos del equipo y habilitar "Mi Equipo" dinamicamente
      return BlocProvider(
        create: (context) => sl<MiActividadBloc>()..add(const CargarMiActividadEvent()),
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
        ),
      );
    },
  );
}

// ============================================
// FUNCIONES AUXILIARES
// ============================================

/// Obtiene accesos rapidos segun el rol del usuario
/// [tieneEquipo]: indica si el jugador tiene equipo asignado en pichanga activa
List<_QuickAccessItem> _getAccesosPorRol(String rol, {bool tieneEquipo = false}) {
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
        // E004-HU-008: Mi Actividad en Vivo (admin tambien puede ser jugador inscrito)
        _QuickAccessItem(
          title: 'Mi Actividad',
          description: 'Ver mi actividad en vivo',
          icon: Icons.sports_soccer,
          color: DesignTokens.primaryColor,
          route: '/mi-actividad',
          enabled: true,
        ),
        _QuickAccessItem(
          title: 'Usuarios',
          description: 'Gestionar usuarios y roles del sistema',
          icon: Icons.people_outline,
          color: DesignTokens.secondaryColor,
          route: '/admin/usuarios',
          enabled: true,
        ),
        _QuickAccessItem(
          title: 'Equipos',
          description: 'Administrar equipos registrados',
          icon: Icons.groups_outlined,
          color: DesignTokens.accentColor,
          route: '/equipos',
          enabled: false,
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
        // E004-HU-008: Mi Actividad en Vivo
        _QuickAccessItem(
          title: 'Mi Actividad',
          description: 'Ver mi actividad en vivo',
          icon: Icons.sports_soccer,
          color: DesignTokens.primaryColor,
          route: '/mi-actividad',
          enabled: true,
        ),
        // Card "Mi Equipo" - habilitada dinamicamente si tiene equipo asignado
        // Navega a /mi-actividad donde se muestra el detalle del equipo
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
// CARD DE ACCESO RAPIDO (MOBILE)
// ============================================

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
