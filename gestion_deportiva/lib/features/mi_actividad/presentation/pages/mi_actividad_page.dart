import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../data/models/models.dart';
import '../bloc/mi_actividad/mi_actividad_bloc.dart';
import '../bloc/mi_actividad/mi_actividad_event.dart';
import '../bloc/mi_actividad/mi_actividad_state.dart';

/// Pagina de Mi Actividad en Vivo
/// E004-HU-008: Mi Actividad en Vivo
/// CA-003: Lista de todos los partidos de la jornada
/// CA-004: Partidos donde participe resaltados
/// CA-005: Partidos donde NO participe visibles
/// CA-006: Mis goles totales de la jornada
/// CA-007: Detalle de mis goles por partido
/// CA-009: Actualizacion en tiempo real
/// CA-010: Sin pichanga activa - mensaje informativo
class MiActividadPage extends StatelessWidget {
  const MiActividadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MiActividadBloc, MiActividadState>(
      builder: (context, state) {
        return ResponsiveLayout(
          mobileBody: _MobileView(state: state),
          desktopBody: _DesktopView(state: state),
        );
      },
    );
  }
}

// ============================================
// VISTA MOBILE
// ============================================

class _MobileView extends StatelessWidget {
  final MiActividadState state;

  const _MobileView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Mi Actividad'),
        centerTitle: true,
        actions: [
          // Boton refresh manual (aunque se actualiza automatico)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MiActividadBloc>().add(const CargarMiActividadEvent());
            },
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (state is MiActividadLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is MiActividadError) {
      final error = state as MiActividadError;
      return _ErrorView(message: error.message);
    }

    if (state is MiActividadLoaded) {
      final actividad = (state as MiActividadLoaded).actividad;

      // CA-010: Sin pichanga activa
      if (!actividad.hayPichangaActiva) {
        return _SinActividadView(
          mensaje: actividad.mensajeSinActividad ??
              'No hay pichanga activa donde estes inscrito',
        );
      }

      return _ActividadContentView(actividad: actividad);
    }

    return const Center(
      child: Text('Cargando...'),
    );
  }
}

// ============================================
// VISTA DESKTOP
// ============================================

class _DesktopView extends StatelessWidget {
  final MiActividadState state;

  const _DesktopView({required this.state});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/mi-actividad',
      title: 'Mi Actividad en Vivo',
      breadcrumbs: const ['Inicio', 'Mi Actividad'],
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
          onPressed: () {
            context.read<MiActividadBloc>().add(const CargarMiActividadEvent());
          },
        ),
      ],
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (state is MiActividadLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is MiActividadError) {
      final error = state as MiActividadError;
      return _ErrorView(message: error.message);
    }

    if (state is MiActividadLoaded) {
      final actividad = (state as MiActividadLoaded).actividad;

      // CA-010: Sin pichanga activa
      if (!actividad.hayPichangaActiva) {
        return _SinActividadView(
          mensaje: actividad.mensajeSinActividad ??
              'No hay pichanga activa donde estes inscrito',
        );
      }

      return _ActividadContentView(actividad: actividad);
    }

    return const Center(
      child: Text('Cargando...'),
    );
  }
}

// ============================================
// VISTA SIN ACTIVIDAD
// ============================================

class _SinActividadView extends StatelessWidget {
  final String mensaje;

  const _SinActividadView({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_soccer_outlined,
                size: DesignTokens.iconSizeXl,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingL),
            Text(
              'Sin Actividad',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              mensaje,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingXl),
            FilledButton.icon(
              onPressed: () => context.go('/fechas'),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Ver proximas pichangas'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// VISTA DE ERROR
// ============================================

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: DesignTokens.iconSizeXl,
              color: DesignTokens.errorColor,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            Text(
              'Error al cargar actividad',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            FilledButton.icon(
              onPressed: () {
                context.read<MiActividadBloc>().add(const CargarMiActividadEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// VISTA DE CONTENIDO CON ACTIVIDAD
// ============================================

class _ActividadContentView extends StatelessWidget {
  final MiActividadResponseModel actividad;

  const _ActividadContentView({required this.actividad});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con resumen
          _ResumenHeader(actividad: actividad),
          const SizedBox(height: DesignTokens.spacingL),

          // Lista de partidos
          _PartidosSection(actividad: actividad),
        ],
      ),
    );
  }
}

// ============================================
// HEADER CON RESUMEN
// ============================================

class _ResumenHeader extends StatelessWidget {
  final MiActividadResponseModel actividad;

  const _ResumenHeader({required this.actividad});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final miEquipo = actividad.miEquipo;
    final equipoColor = miEquipo != null
        ? _hexToColor(miEquipo.colorHex)
        : DesignTokens.primaryColor;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            equipoColor.withValues(alpha: 0.15),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: equipoColor.withValues(alpha: 0.3),
        ),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Row(
        children: [
          // Goles totales
          Expanded(
            child: Column(
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: DesignTokens.iconSizeXl,
                  color: DesignTokens.accentColor,
                ),
                const SizedBox(height: DesignTokens.spacingS),
                Text(
                  '${actividad.misGolesTotales}',
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                    color: DesignTokens.accentColor,
                  ),
                ),
                Text(
                  'Mis Goles Hoy',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Separador
          Container(
            width: 1,
            height: 80,
            color: colorScheme.outlineVariant,
          ),

          // Mi equipo
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: equipoColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: equipoColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingS),
                Text(
                  miEquipo?.color.toUpperCase() ?? 'SIN EQUIPO',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                    color: equipoColor,
                  ),
                ),
                Text(
                  'Mi Equipo',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}

// ============================================
// SECCION DE PARTIDOS
// ============================================

class _PartidosSection extends StatelessWidget {
  final MiActividadResponseModel actividad;

  const _PartidosSection({required this.actividad});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final partidos = actividad.partidos;

    // Buscar partido en curso donde participo
    final partidoEnCurso = partidos.where((p) => p.enCurso && p.esMiPartido).firstOrNull;

    if (partidos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.sports_outlined,
                size: DesignTokens.iconSizeXl,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                'Aun no hay partidos',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card EN VIVO si hay partido activo donde participo
        if (partidoEnCurso != null) ...[
          _PartidoEnVivoCard(partido: partidoEnCurso, miEquipo: actividad.miEquipo),
          const SizedBox(height: DesignTokens.spacingL),
        ],

        // Tabla de partidos
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                child: Row(
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      size: DesignTokens.iconSizeM,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Text(
                      'Partidos (${partidos.length})',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Cabecera de tabla
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Estado',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Enfrentamiento',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Score',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Filas de partidos
              ...partidos.map((partido) => _PartidoRow(
                partido: partido,
                esMiPartido: partido.esMiPartido,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================
// CARD PARTIDO EN VIVO (estilo admin)
// ============================================

class _PartidoEnVivoCard extends StatelessWidget {
  final PartidoActividadModel partido;
  final MiEquipoActividadModel? miEquipo;

  const _PartidoEnVivoCard({required this.partido, this.miEquipo});

  Color _colorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'naranja':
        return const Color(0xFFFF9800);
      case 'verde':
        return const Color(0xFF4CAF50);
      case 'azul':
        return const Color(0xFF2196F3);
      case 'rojo':
        return const Color(0xFFF44336);
      case 'amarillo':
        return const Color(0xFFFFEB3B);
      case 'blanco':
        return const Color(0xFFFFFFFF);
      default:
        return const Color(0xFFCCCCCC);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final colorLocal = _colorFromName(partido.equipoLocal);
    final colorVisitante = _colorFromName(partido.equipoVisitante);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.successColor.withValues(alpha: 0.2),
            DesignTokens.successColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: DesignTokens.successColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header EN VIVO
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.successColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DesignTokens.radiusL - 2),
                topRight: Radius.circular(DesignTokens.radiusL - 2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingXs),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'EN VIVO',
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${partido.duracionMinutos}:00',
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              children: [
                // Equipos y score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Equipo Local
                    Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorLocal,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorLocal.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              partido.equipoLocal[0].toUpperCase(),
                              style: textTheme.titleLarge?.copyWith(
                                color: colorLocal == const Color(0xFFFFFFFF) ||
                                        colorLocal == const Color(0xFFFFEB3B)
                                    ? Colors.black
                                    : Colors.white,
                                fontWeight: DesignTokens.fontWeightBold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacingXs),
                        Text(
                          partido.equipoLocal.toUpperCase(),
                          style: textTheme.labelMedium?.copyWith(
                            color: colorLocal,
                            fontWeight: DesignTokens.fontWeightBold,
                          ),
                        ),
                        Text(
                          'Local',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    // VS y Score
                    Column(
                      children: [
                        Text(
                          'vs',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spacingL,
                            vertical: DesignTokens.spacingM,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                            border: Border.all(
                              color: DesignTokens.successColor,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '${partido.golesLocal}  -  ${partido.golesVisitante}',
                            style: textTheme.displaySmall?.copyWith(
                              fontWeight: DesignTokens.fontWeightBold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Equipo Visitante
                    Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorVisitante,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorVisitante.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              partido.equipoVisitante[0].toUpperCase(),
                              style: textTheme.titleLarge?.copyWith(
                                color: colorVisitante == const Color(0xFFFFFFFF) ||
                                        colorVisitante == const Color(0xFFFFEB3B)
                                    ? Colors.black
                                    : Colors.white,
                                fontWeight: DesignTokens.fontWeightBold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacingXs),
                        Text(
                          partido.equipoVisitante.toUpperCase(),
                          style: textTheme.labelMedium?.copyWith(
                            color: colorVisitante,
                            fontWeight: DesignTokens.fontWeightBold,
                          ),
                        ),
                        Text(
                          'Visitante',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// FILA DE PARTIDO EN TABLA
// ============================================

class _PartidoRow extends StatelessWidget {
  final PartidoActividadModel partido;
  final bool esMiPartido;

  const _PartidoRow({required this.partido, required this.esMiPartido});

  Color _colorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'naranja':
        return const Color(0xFFFF9800);
      case 'verde':
        return const Color(0xFF4CAF50);
      case 'azul':
        return const Color(0xFF2196F3);
      case 'rojo':
        return const Color(0xFFF44336);
      case 'amarillo':
        return const Color(0xFFFFEB3B);
      case 'blanco':
        return const Color(0xFFFFFFFF);
      default:
        return const Color(0xFFCCCCCC);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final colorLocal = _colorFromName(partido.equipoLocal);
    final colorVisitante = _colorFromName(partido.equipoVisitante);

    // Colores de estado
    Color estadoColor;
    String estadoLabel;
    switch (partido.estado) {
      case 'en_curso':
        estadoColor = DesignTokens.successColor;
        estadoLabel = 'En curso';
        break;
      case 'finalizado':
        estadoColor = Colors.orange;
        estadoLabel = 'Finalizado';
        break;
      default:
        estadoColor = Colors.blue;
        estadoLabel = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: esMiPartido
            ? DesignTokens.primaryColor.withValues(alpha: 0.05)
            : null,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          left: esMiPartido
              ? BorderSide(color: DesignTokens.primaryColor, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Estado
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                border: Border.all(color: estadoColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (partido.estado == 'en_curso')
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: estadoColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    estadoLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: estadoColor,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Enfrentamiento
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Equipo local
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorLocal,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Text(
                    partido.equipoLocal.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorLocal == const Color(0xFFFFFFFF) ||
                              colorLocal == const Color(0xFFFFEB3B)
                          ? Colors.black
                          : Colors.white,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
                  child: Text(
                    'vs',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // Equipo visitante
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorVisitante,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Text(
                    partido.equipoVisitante.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorVisitante == const Color(0xFFFFFFFF) ||
                              colorVisitante == const Color(0xFFFFEB3B)
                          ? Colors.black
                          : Colors.white,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Score
          SizedBox(
            width: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Text(
                '${partido.golesLocal} - ${partido.golesVisitante}',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// CARD DE PARTIDO
// ============================================

class _PartidoCard extends StatelessWidget {
  final PartidoActividadModel partido;
  final String? miEquipoColor;

  const _PartidoCard({
    required this.partido,
    this.miEquipoColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // CA-004: Resaltar si es mi partido
    final colorLocal = _colorFromName(partido.equipoLocal);
    final colorVisitante = _colorFromName(partido.equipoVisitante);

    // Color del borde si es mi partido
    Color? borderColor;
    if (partido.esMiPartido && miEquipoColor != null) {
      borderColor = _colorFromName(miEquipoColor!);
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border(
          left: BorderSide(
            color: partido.esMiPartido
                ? (borderColor ?? colorScheme.primary)
                : Colors.transparent,
            width: 4,
          ),
          top: BorderSide(color: colorScheme.outlineVariant),
          right: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: partido.enCurso
              ? () {
                  // RN-008: Navegar a score en vivo
                  context.go('/partidos/${partido.partidoId}/score');
                }
              : null,
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Column(
              children: [
                // Header con estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _EstadoBadge(estado: partido.estado),
                    if (partido.esMiPartido)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingS,
                          vertical: DesignTokens.spacingXxs,
                        ),
                        decoration: BoxDecoration(
                          color: (borderColor ?? colorScheme.primary)
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: borderColor ?? colorScheme.primary,
                            ),
                            const SizedBox(width: DesignTokens.spacingXxs),
                            Text(
                              'Participe',
                              style: textTheme.labelSmall?.copyWith(
                                color: borderColor ?? colorScheme.primary,
                                fontWeight: DesignTokens.fontWeightMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: DesignTokens.spacingM),

                // Equipos y marcador
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Equipo local
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorLocal,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorLocal.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spacingXs),
                          Text(
                            partido.equipoLocal.toUpperCase(),
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: DesignTokens.fontWeightSemiBold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Marcador
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingL,
                        vertical: DesignTokens.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: partido.enCurso
                            ? DesignTokens.successColor.withValues(alpha: 0.1)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      ),
                      child: Text(
                        '${partido.golesLocal} - ${partido.golesVisitante}',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                    ),

                    // Equipo visitante
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorVisitante,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorVisitante.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spacingXs),
                          Text(
                            partido.equipoVisitante.toUpperCase(),
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: DesignTokens.fontWeightSemiBold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // CA-007: Mis goles en este partido
                if (partido.esMiPartido && partido.misGoles > 0) ...[
                  const SizedBox(height: DesignTokens.spacingM),
                  const Divider(),
                  const SizedBox(height: DesignTokens.spacingS),
                  _MisGolesDetalle(partido: partido),
                ],

                // Boton ver partido en vivo
                if (partido.enCurso) ...[
                  const SizedBox(height: DesignTokens.spacingM),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.go('/partidos/${partido.partidoId}/score');
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Ver partido en vivo'),
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignTokens.successColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'naranja':
        return const Color(0xFFFF9800);
      case 'verde':
        return const Color(0xFF4CAF50);
      case 'azul':
        return const Color(0xFF2196F3);
      case 'rojo':
        return const Color(0xFFF44336);
      case 'amarillo':
        return const Color(0xFFFFEB3B);
      case 'blanco':
        return const Color(0xFFFFFFFF);
      default:
        return const Color(0xFFCCCCCC);
    }
  }
}

// ============================================
// BADGE DE ESTADO
// ============================================

class _EstadoBadge extends StatefulWidget {
  final String estado;

  const _EstadoBadge({required this.estado});

  @override
  State<_EstadoBadge> createState() => _EstadoBadgeState();
}

class _EstadoBadgeState extends State<_EstadoBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    if (widget.estado == 'en_curso') {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..repeat(reverse: true);
      _animation = Tween<double>(begin: 0.6, end: 1.0).animate(_controller!);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (widget.estado) {
      case 'en_curso':
        bgColor = DesignTokens.errorColor.withValues(alpha: 0.1);
        textColor = DesignTokens.errorColor;
        label = 'EN VIVO';
        icon = Icons.circle;
        break;
      case 'finalizado':
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        label = 'FINALIZADO';
        icon = Icons.check_circle;
        break;
      default:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        label = 'PENDIENTE';
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.estado == 'en_curso' && _animation != null)
            AnimatedBuilder(
              animation: _animation!,
              builder: (context, child) {
                return Icon(
                  icon,
                  size: 10,
                  color: textColor.withValues(alpha: _animation!.value),
                );
              },
            )
          else
            Icon(
              icon,
              size: 12,
              color: textColor,
            ),
          const SizedBox(width: DesignTokens.spacingXxs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: DesignTokens.fontWeightBold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// DETALLE DE MIS GOLES
// ============================================

class _MisGolesDetalle extends StatelessWidget {
  final PartidoActividadModel partido;

  const _MisGolesDetalle({required this.partido});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_soccer,
            size: DesignTokens.iconSizeM,
            color: DesignTokens.accentColor,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis goles: ${partido.misGoles}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: DesignTokens.accentColor,
                  ),
                ),
                if (partido.misGolesDetalle.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.spacingXxs),
                  Text(
                    partido.misGolesDetalle
                        .map((g) => "Min ${g.minuto}'")
                        .join(', '),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
