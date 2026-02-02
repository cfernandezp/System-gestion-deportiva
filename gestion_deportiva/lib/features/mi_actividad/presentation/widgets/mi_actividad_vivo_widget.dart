import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/models.dart';
import '../bloc/mi_actividad/mi_actividad_bloc.dart';
import '../bloc/mi_actividad/mi_actividad_event.dart';
import '../bloc/mi_actividad/mi_actividad_state.dart';

/// Widget de Mi Actividad en Vivo para Dashboard
/// E004-HU-008: Mi Actividad en Vivo
/// CA-001: Solo visible cuando hay pichanga activa donde el jugador esta inscrito
/// CA-002: Muestra nombre pichanga, equipo asignado, goles totales
/// RN-007: Ubicar en parte superior del Dashboard, prominente
class MiActividadVivoWidget extends StatelessWidget {
  const MiActividadVivoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<MiActividadBloc>()..add(const CargarMiActividadEvent()),
      child: const _MiActividadVivoContent(),
    );
  }
}

class _MiActividadVivoContent extends StatelessWidget {
  const _MiActividadVivoContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MiActividadBloc, MiActividadState>(
      builder: (context, state) {
        // CA-001: Solo mostrar si hay pichanga activa
        if (state is MiActividadLoaded && state.actividad.hayPichangaActiva) {
          return _ActividadActivaCard(actividad: state.actividad);
        }

        // No mostrar nada si no hay pichanga activa o esta cargando
        return const SizedBox.shrink();
      },
    );
  }
}

/// Card de actividad activa
/// RN-007: Fondo con gradiente, icono pulsante, tamano destacado
class _ActividadActivaCard extends StatefulWidget {
  final MiActividadResponseModel actividad;

  const _ActividadActivaCard({required this.actividad});

  @override
  State<_ActividadActivaCard> createState() => _ActividadActivaCardState();
}

class _ActividadActivaCardState extends State<_ActividadActivaCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Animacion pulsante para indicador "EN VIVO"
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final actividad = widget.actividad;
    final pichanga = actividad.pichangaActiva!;
    final miEquipo = actividad.miEquipo;
    final partidoEnCurso = actividad.partidoEnCurso;

    // Color del equipo para el borde
    final equipoColor = miEquipo != null
        ? _hexToColor(miEquipo.colorHex)
        : DesignTokens.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primaryColor.withValues(alpha: 0.15),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: equipoColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: DesignTokens.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/mi-actividad'),
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con indicador EN VIVO
                Row(
                  children: [
                    // Indicador pulsante
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: DesignTokens.successColor.withValues(
                              alpha: _pulseAnimation.value,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: DesignTokens.successColor.withValues(
                                  alpha: _pulseAnimation.value * 0.5,
                                ),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Text(
                      'ESTAS JUGANDO',
                      style: textTheme.titleSmall?.copyWith(
                        color: DesignTokens.successColor,
                        fontWeight: DesignTokens.fontWeightBold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // Flecha para ver mas
                    Icon(
                      Icons.arrow_forward_ios,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),

                const SizedBox(height: DesignTokens.spacingM),
                const Divider(height: 1),
                const SizedBox(height: DesignTokens.spacingM),

                // Info de la pichanga
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: DesignTokens.spacingXs),
                    Expanded(
                      child: Text(
                        pichanga.lugar,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: DesignTokens.spacingXs),
                    Text(
                      pichanga.fecha,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DesignTokens.spacingM),

                // Cards de equipo y goles
                Row(
                  children: [
                    // Mi equipo
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(DesignTokens.spacingM),
                        decoration: BoxDecoration(
                          color: equipoColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                          border: Border.all(
                            color: equipoColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: equipoColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spacingXs),
                            Text(
                              miEquipo?.color.toUpperCase() ?? 'Sin equipo',
                              style: textTheme.labelMedium?.copyWith(
                                color: equipoColor,
                                fontWeight: DesignTokens.fontWeightSemiBold,
                              ),
                            ),
                            Text(
                              'Mi equipo',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingM),
                    // Mis goles
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(DesignTokens.spacingM),
                        decoration: BoxDecoration(
                          color: DesignTokens.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                          border: Border.all(
                            color: DesignTokens.accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.sports_soccer,
                              size: DesignTokens.iconSizeM,
                              color: DesignTokens.accentColor,
                            ),
                            const SizedBox(height: DesignTokens.spacingXs),
                            Text(
                              '${actividad.misGolesTotales}',
                              style: textTheme.titleLarge?.copyWith(
                                color: DesignTokens.accentColor,
                                fontWeight: DesignTokens.fontWeightBold,
                              ),
                            ),
                            Text(
                              'Mis goles',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // CA-008: Mostrar partido en curso si existe
                if (partidoEnCurso != null && partidoEnCurso.partidoId != null) ...[
                  const SizedBox(height: DesignTokens.spacingM),
                  _PartidoEnCursoMini(
                    actividad: actividad,
                    estoyJugando: partidoEnCurso.estoyJugando,
                  ),
                ],

                const SizedBox(height: DesignTokens.spacingM),

                // Boton ver actividad completa
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => context.go('/mi-actividad'),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Ver actividad completa'),
                    style: TextButton.styleFrom(
                      foregroundColor: DesignTokens.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

/// Mini card del partido en curso
class _PartidoEnCursoMini extends StatelessWidget {
  final MiActividadResponseModel actividad;
  final bool estoyJugando;

  const _PartidoEnCursoMini({
    required this.actividad,
    required this.estoyJugando,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Buscar partido en curso en la lista
    final partidoEnCurso = actividad.partidos.where((p) => p.enCurso).firstOrNull;

    if (partidoEnCurso == null) return const SizedBox.shrink();

    final colorLocal = _colorFromName(partidoEnCurso.equipoLocal);
    final colorVisitante = _colorFromName(partidoEnCurso.equipoVisitante);

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header EN VIVO
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: DesignTokens.errorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingXs),
              Text(
                'EN VIVO',
                style: textTheme.labelSmall?.copyWith(
                  color: DesignTokens.errorColor,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              if (partidoEnCurso.minutoActual != null) ...[
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  "Min ${partidoEnCurso.minutoActual}'",
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),

          // Score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Equipo local
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colorLocal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingXxs),
                  Text(
                    partidoEnCurso.equipoLocal.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: DesignTokens.spacingM),

              // Marcador
              Text(
                '${partidoEnCurso.golesLocal} - ${partidoEnCurso.golesVisitante}',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),

              const SizedBox(width: DesignTokens.spacingM),

              // Equipo visitante
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colorVisitante,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingXxs),
                  Text(
                    partidoEnCurso.equipoVisitante.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Indicador si estoy jugando
          if (estoyJugando) ...[
            const SizedBox(height: DesignTokens.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: 12,
                    color: DesignTokens.successColor,
                  ),
                  const SizedBox(width: DesignTokens.spacingXxs),
                  Text(
                    'Estas jugando',
                    style: textTheme.labelSmall?.copyWith(
                      color: DesignTokens.successColor,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
