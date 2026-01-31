import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/partido_model.dart';
import '../bloc/partido/partido.dart';

/// Widget para mostrar partido activo con temporizador
/// E004-HU-001: Iniciar Partido
/// E004-HU-002: Temporizador con Alarma
/// CA-003: Temporizador con cuenta regresiva
/// CA-004: Indicador de partido en curso con equipos y tiempo restante
/// CA-005: Botones pausar/reanudar (solo admin)
/// CA-009: Boton pantalla completa
class PartidoEnVivoWidget extends StatelessWidget {
  /// Indica si el usuario es admin y puede pausar/reanudar
  final bool esAdmin;

  /// Callback opcional cuando el partido cambia de estado
  final VoidCallback? onEstadoCambiado;

  /// Callback para abrir pantalla completa
  final void Function(PartidoModel partido)? onPantallaCompleta;

  const PartidoEnVivoWidget({
    super.key,
    this.esAdmin = false,
    this.onEstadoCambiado,
    this.onPantallaCompleta,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PartidoBloc, PartidoState>(
      listener: (context, state) {
        // Notificar cambios de estado
        if (state is PartidoEnCurso || state is PartidoPausado) {
          onEstadoCambiado?.call();
        }

        // Mostrar errores
        if (state is PartidoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: DesignTokens.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Mostrar mensaje de pausa
        if (state is PartidoPausado) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.pause_circle, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      state.message.isNotEmpty
                          ? state.message
                          : 'Partido pausado',
                    ),
                  ),
                ],
              ),
              backgroundColor: DesignTokens.accentColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        // Estado de carga
        if (state is PartidoLoading) {
          return _buildLoadingState(context);
        }

        // Partido en curso
        if (state is PartidoEnCurso) {
          return _PartidoEnCursoCard(
            partido: state.partido,
            puedePausar: esAdmin && state.puedePausar,
            isProcesando: false,
            onPantallaCompleta: onPantallaCompleta,
          );
        }

        // Partido pausado
        if (state is PartidoPausado) {
          return _PartidoPausadoCard(
            partido: state.partido,
            puedeReanudar: esAdmin && state.puedeReanudar,
            isProcesando: false,
            onPantallaCompleta: onPantallaCompleta,
          );
        }

        // Procesando operacion
        if (state is PartidoProcesando) {
          if (state.partido != null) {
            if (state.operacion == 'pausando') {
              return _PartidoEnCursoCard(
                partido: state.partido!,
                puedePausar: false,
                isProcesando: true,
              );
            } else if (state.operacion == 'reanudando') {
              return _PartidoPausadoCard(
                partido: state.partido!,
                puedeReanudar: false,
                isProcesando: true,
              );
            }
          }
          return _buildLoadingState(context);
        }

        // Error con partido previo
        if (state is PartidoError && state.partido != null) {
          return _buildErrorWithRetry(context, state);
        }

        // Sin partido activo - no mostrar nada
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Cargando partido...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWithRetry(BuildContext context, PartidoError state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(color: DesignTokens.errorColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: DesignTokens.iconSizeXl,
              color: DesignTokens.errorColor,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            if (state.fechaId != null)
              FilledButton.icon(
                onPressed: () {
                  context.read<PartidoBloc>().add(
                        CargarPartidoActivoEvent(fechaId: state.fechaId!),
                      );
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

/// Card de partido en curso con temporizador activo
class _PartidoEnCursoCard extends StatelessWidget {
  final PartidoModel partido;
  final bool puedePausar;
  final bool isProcesando;
  final void Function(PartidoModel partido)? onPantallaCompleta;

  const _PartidoEnCursoCard({
    required this.partido,
    required this.puedePausar,
    required this.isProcesando,
    this.onPantallaCompleta,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determinar si el tiempo esta por acabar (menos de 2 minutos)
    final tiempoRestante = partido.tiempoRestanteSegundos;
    final tiempoCritico = tiempoRestante <= 120 && tiempoRestante > 0;
    final tiempoTerminado = partido.tiempoTerminado;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(
          color: tiempoTerminado
              ? DesignTokens.accentColor
              : DesignTokens.successColor,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: tiempoTerminado
                  ? DesignTokens.accentColor
                  : DesignTokens.successColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusL - 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tiempoTerminado ? Icons.flag : Icons.play_circle,
                  color: Colors.white,
                  size: DesignTokens.iconSizeS,
                ),
                const SizedBox(width: DesignTokens.spacingXs),
                Text(
                  tiempoTerminado ? 'TIEMPO TERMINADO' : 'PARTIDO EN CURSO',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: DesignTokens.fontWeightBold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              children: [
                // Equipos enfrentados
                _EnfrentamientoDisplay(
                  equipoLocal: partido.equipoLocal.color,
                  equipoVisitante: partido.equipoVisitante.color,
                ),

                const SizedBox(height: DesignTokens.spacingL),

                // Temporizador grande
                _TemporizadorDisplay(
                  tiempoRestanteSegundos: tiempoRestante,
                  tiempoCritico: tiempoCritico,
                  tiempoTerminado: tiempoTerminado,
                ),

                const SizedBox(height: DesignTokens.spacingS),

                // Duracion total
                Text(
                  'Duracion: ${partido.duracionMinutos} minutos',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                // CA-009: Boton pantalla completa
                const SizedBox(height: DesignTokens.spacingM),
                OutlinedButton.icon(
                  onPressed: () => onPantallaCompleta?.call(partido),
                  icon: const Icon(Icons.fullscreen),
                  label: const Text('Pantalla Completa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                ),

                // Boton pausar (solo admin)
                if (puedePausar && !tiempoTerminado) ...[
                  const SizedBox(height: DesignTokens.spacingL),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isProcesando
                          ? null
                          : () {
                              context.read<PartidoBloc>().add(
                                    PausarPartidoEvent(partidoId: partido.id),
                                  );
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesignTokens.accentColor,
                        side: BorderSide(color: DesignTokens.accentColor),
                        padding: const EdgeInsets.all(DesignTokens.spacingM),
                      ),
                      icon: isProcesando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.pause),
                      label: const Text('Pausar Partido'),
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

/// Card de partido pausado
class _PartidoPausadoCard extends StatelessWidget {
  final PartidoModel partido;
  final bool puedeReanudar;
  final bool isProcesando;
  final void Function(PartidoModel partido)? onPantallaCompleta;

  const _PartidoPausadoCard({
    required this.partido,
    required this.puedeReanudar,
    required this.isProcesando,
    this.onPantallaCompleta,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(
          color: DesignTokens.accentColor,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header con estado pausado
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.accentColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusL - 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.pause_circle,
                  color: Colors.white,
                  size: DesignTokens.iconSizeS,
                ),
                const SizedBox(width: DesignTokens.spacingXs),
                Text(
                  'PARTIDO PAUSADO',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: DesignTokens.fontWeightBold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              children: [
                // Equipos enfrentados
                _EnfrentamientoDisplay(
                  equipoLocal: partido.equipoLocal.color,
                  equipoVisitante: partido.equipoVisitante.color,
                ),

                const SizedBox(height: DesignTokens.spacingL),

                // Temporizador (pausado)
                _TemporizadorDisplay(
                  tiempoRestanteSegundos: partido.tiempoRestanteSegundos,
                  tiempoCritico: false,
                  tiempoTerminado: false,
                  pausado: true,
                ),

                const SizedBox(height: DesignTokens.spacingS),

                // Mensaje de pausa
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingM,
                    vertical: DesignTokens.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: DesignTokens.iconSizeS,
                        color: DesignTokens.accentColor,
                      ),
                      const SizedBox(width: DesignTokens.spacingXs),
                      Text(
                        'El temporizador esta detenido',
                        style: textTheme.bodySmall?.copyWith(
                          color: DesignTokens.accentColor,
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                ),

                // CA-009: Boton pantalla completa
                const SizedBox(height: DesignTokens.spacingM),
                OutlinedButton.icon(
                  onPressed: () => onPantallaCompleta?.call(partido),
                  icon: const Icon(Icons.fullscreen),
                  label: const Text('Pantalla Completa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),

                // Boton reanudar (solo admin)
                if (puedeReanudar) ...[
                  const SizedBox(height: DesignTokens.spacingL),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isProcesando
                          ? null
                          : () {
                              context.read<PartidoBloc>().add(
                                    ReanudarPartidoEvent(partidoId: partido.id),
                                  );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignTokens.successColor,
                        padding: const EdgeInsets.all(DesignTokens.spacingM),
                      ),
                      icon: isProcesando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: const Text('Reanudar Partido'),
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

/// Display de equipos enfrentados
class _EnfrentamientoDisplay extends StatelessWidget {
  final ColorEquipo equipoLocal;
  final ColorEquipo equipoVisitante;

  const _EnfrentamientoDisplay({
    required this.equipoLocal,
    required this.equipoVisitante,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Equipo local
        Expanded(
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: equipoLocal.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: equipoLocal.borderColor,
                    width: 3,
                  ),
                  boxShadow: DesignTokens.shadowMd,
                ),
                child: Center(
                  child: Text(
                    equipoLocal.displayName[0].toUpperCase(),
                    style: textTheme.headlineSmall?.copyWith(
                      color: equipoLocal.textColor,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                equipoLocal.displayName.toUpperCase(),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                  color: equipoLocal.color,
                ),
              ),
              Text(
                'Local',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // VS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
          child: Text(
            'VS',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        // Equipo visitante
        Expanded(
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: equipoVisitante.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: equipoVisitante.borderColor,
                    width: 3,
                  ),
                  boxShadow: DesignTokens.shadowMd,
                ),
                child: Center(
                  child: Text(
                    equipoVisitante.displayName[0].toUpperCase(),
                    style: textTheme.headlineSmall?.copyWith(
                      color: equipoVisitante.textColor,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                equipoVisitante.displayName.toUpperCase(),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                  color: equipoVisitante.color,
                ),
              ),
              Text(
                'Visitante',
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

/// Display del temporizador
/// E004-HU-002: Soporta tiempo negativo (tiempo extra)
class _TemporizadorDisplay extends StatelessWidget {
  final int tiempoRestanteSegundos;
  final bool tiempoCritico;
  final bool tiempoTerminado;
  final bool pausado;

  const _TemporizadorDisplay({
    required this.tiempoRestanteSegundos,
    required this.tiempoCritico,
    required this.tiempoTerminado,
    this.pausado = false,
  });

  /// RN-006: Formato MM:SS o -MM:SS para tiempo extra
  String get _tiempoFormateado {
    final esNegativo = tiempoRestanteSegundos < 0;
    final segundosAbsolutos = tiempoRestanteSegundos.abs();
    final minutos = segundosAbsolutos ~/ 60;
    final segs = segundosAbsolutos % 60;
    final tiempo =
        '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
    return esNegativo ? '-$tiempo' : tiempo;
  }

  /// Indica si estamos en tiempo extra (negativo)
  bool get _esTiempoExtra => tiempoRestanteSegundos < 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Determinar color del temporizador
    Color tiempoColor;
    if (tiempoTerminado) {
      tiempoColor = DesignTokens.errorColor;
    } else if (pausado) {
      tiempoColor = DesignTokens.accentColor;
    } else if (tiempoCritico) {
      tiempoColor = DesignTokens.errorColor;
    } else {
      tiempoColor = DesignTokens.successColor;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: tiempoTerminado ? 0.5 : 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, opacity, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingXl,
            vertical: DesignTokens.spacingM,
          ),
          decoration: BoxDecoration(
            color: tiempoColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: tiempoColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Etiqueta
              Text(
                pausado
                    ? 'TIEMPO PAUSADO'
                    : _esTiempoExtra
                        ? 'TIEMPO EXTRA'
                        : tiempoTerminado
                            ? 'FIN DEL TIEMPO'
                            : 'TIEMPO RESTANTE',
                style: textTheme.labelSmall?.copyWith(
                  color: tiempoColor,
                  fontWeight: DesignTokens.fontWeightMedium,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXs),
              // Tiempo grande
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: tiempoColor.withValues(
                    alpha: tiempoTerminado && !pausado
                        ? (opacity < 0.75 ? 0.3 : 1.0)
                        : 1.0,
                  ),
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                ),
                child: Text(_tiempoFormateado),
              ),
            ],
          ),
        );
      },
    );
  }
}
