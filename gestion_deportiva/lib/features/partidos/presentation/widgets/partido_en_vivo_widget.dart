import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/partido_model.dart';
import '../bloc/goles/goles.dart';
import '../bloc/partido/partido.dart';
import 'registrar_gol_dialog.dart';

/// Widget para mostrar partido activo estilo Champions League
/// E004-HU-001: Iniciar Partido
/// E004-HU-002: Temporizador con Alarma
/// CA-003: Temporizador con cuenta regresiva
/// CA-004: Indicador de partido en curso con equipos y tiempo restante
/// CA-005: Botones pausar/reanudar (solo admin)
/// CA-009: Boton pantalla completa
///
/// Diseño deportivo premium basado en UEFA Champions League App
class PartidoEnVivoWidget extends StatelessWidget {
  /// Indica si el usuario es admin y puede pausar/reanudar
  final bool esAdmin;

  /// Callback opcional cuando el partido cambia de estado
  final VoidCallback? onEstadoCambiado;

  /// Callback para abrir pantalla completa
  final void Function(PartidoModel partido)? onPantallaCompleta;

  /// Callback para anotar gol (solo si esAdmin)
  /// DEPRECATED: Use los botones de gol integrados en el widget
  final void Function(PartidoModel partido)? onAnotarGol;

  /// GolesBloc para registrar goles directamente
  /// Si se proporciona, se usaran los botones de gol por equipo
  final GolesBloc? golesBloc;

  /// Callback para finalizar partido (solo si esAdmin)
  final void Function(PartidoModel partido)? onFinalizarPartido;

  const PartidoEnVivoWidget({
    super.key,
    this.esAdmin = false,
    this.onEstadoCambiado,
    this.onPantallaCompleta,
    this.onAnotarGol,
    this.onFinalizarPartido,
    this.golesBloc,
  });

  @override
  Widget build(BuildContext context) {
    // Construir el contenido del partido
    final partidoContent = _buildPartidoContent(context);

    // Si hay GolesBloc, envolver con BlocListener para actualizar el marcador
    if (golesBloc != null) {
      return BlocListener<GolesBloc, GolesState>(
        bloc: golesBloc,
        listener: (context, golesState) {
          // Cuando se registra un gol, actualizar el marcador en PartidoBloc
          if (golesState is GolRegistrado) {
            context.read<PartidoBloc>().add(
                  ActualizarMarcadorEvent(
                    golesLocal: golesState.marcador.golesLocal,
                    golesVisitante: golesState.marcador.golesVisitante,
                  ),
                );
          }
          // Cuando se elimina un gol, actualizar el marcador en PartidoBloc
          if (golesState is GolEliminado) {
            context.read<PartidoBloc>().add(
                  ActualizarMarcadorEvent(
                    golesLocal: golesState.marcador.golesLocal,
                    golesVisitante: golesState.marcador.golesVisitante,
                  ),
                );
          }
        },
        child: partidoContent,
      );
    }

    return partidoContent;
  }

  Widget _buildPartidoContent(BuildContext context) {
    return BlocConsumer<PartidoBloc, PartidoState>(
      listenWhen: (previous, current) {
        if (previous is PartidoInitial || previous is PartidoLoading) {
          return false;
        }
        return true;
      },
      listener: (context, state) {
        if (onEstadoCambiado != null) {
          if (state is PartidoEnCurso || state is PartidoPausado) {
            onEstadoCambiado?.call();
          }
        }

        if (state is PartidoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: DesignTokens.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

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
        if (state is PartidoLoading) {
          return _buildLoadingState(context);
        }

        if (state is PartidoEnCurso) {
          return _PartidoEnVivoCard(
            partido: state.partido,
            estado: _EstadoPartidoVisual.enVivo,
            puedePausar: esAdmin && state.puedePausar,
            puedeReanudar: false,
            isProcesando: false,
            esAdmin: esAdmin,
            onPantallaCompleta: onPantallaCompleta,
            onAnotarGol: onAnotarGol,
            onFinalizarPartido: onFinalizarPartido,
            golesBloc: golesBloc,
          );
        }

        if (state is PartidoPausado) {
          return _PartidoEnVivoCard(
            partido: state.partido,
            estado: _EstadoPartidoVisual.pausado,
            puedePausar: false,
            puedeReanudar: esAdmin && state.puedeReanudar,
            isProcesando: false,
            esAdmin: esAdmin,
            onPantallaCompleta: onPantallaCompleta,
            onAnotarGol: onAnotarGol,
            onFinalizarPartido: onFinalizarPartido,
            golesBloc: golesBloc,
          );
        }

        if (state is PartidoProcesando) {
          if (state.partido != null) {
            final esPausando = state.operacion == 'pausando';
            return _PartidoEnVivoCard(
              partido: state.partido!,
              estado: esPausando
                  ? _EstadoPartidoVisual.enVivo
                  : _EstadoPartidoVisual.pausado,
              puedePausar: false,
              puedeReanudar: false,
              isProcesando: true,
              esAdmin: esAdmin,
              onPantallaCompleta: onPantallaCompleta,
              onAnotarGol: onAnotarGol,
              onFinalizarPartido: onFinalizarPartido,
              golesBloc: golesBloc,
            );
          }
          return _buildLoadingState(context);
        }

        if (state is PartidoError && state.partido != null) {
          return _buildErrorWithRetry(context, state);
        }

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

/// Estados visuales del partido
enum _EstadoPartidoVisual {
  enVivo,
  pausado,
  tiempoExtra,
}

/// Card principal del partido en vivo - Estilo Champions League
class _PartidoEnVivoCard extends StatelessWidget {
  final PartidoModel partido;
  final _EstadoPartidoVisual estado;
  final bool puedePausar;
  final bool puedeReanudar;
  final bool isProcesando;
  final bool esAdmin;
  final void Function(PartidoModel partido)? onPantallaCompleta;
  final void Function(PartidoModel partido)? onAnotarGol;
  final void Function(PartidoModel partido)? onFinalizarPartido;
  final GolesBloc? golesBloc;

  const _PartidoEnVivoCard({
    required this.partido,
    required this.estado,
    required this.puedePausar,
    required this.puedeReanudar,
    required this.isProcesando,
    required this.esAdmin,
    this.onPantallaCompleta,
    this.onAnotarGol,
    this.onFinalizarPartido,
    this.golesBloc,
  });

  /// Determina el estado visual real considerando tiempo extra
  _EstadoPartidoVisual get estadoReal {
    if (partido.tiempoTerminado && estado == _EstadoPartidoVisual.enVivo) {
      return _EstadoPartidoVisual.tiempoExtra;
    }
    return estado;
  }

  /// Color del estado
  Color get colorEstado {
    switch (estadoReal) {
      case _EstadoPartidoVisual.enVivo:
        return DesignTokens.successColor;
      case _EstadoPartidoVisual.pausado:
        return DesignTokens.accentColor;
      case _EstadoPartidoVisual.tiempoExtra:
        return DesignTokens.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(
          color: colorEstado,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con estado y tiempo transcurrido (calculado dinamicamente)
          _HeaderEstadoPartido(
            estado: estadoReal,
            tiempoTranscurrido: partido.tiempoTranscurridoDisplay,
            duracionMinutos: partido.duracionMinutos,
            enTiempoExtra: partido.enTiempoExtra,
            tiempoExtraSegundos: partido.tiempoExtraSegundos,
            onPantallaCompleta: onPantallaCompleta != null
                ? () => onPantallaCompleta!(partido)
                : null,
          ),

          // Contenido principal - Compacto
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            child: Column(
              children: [
                // Equipos con indicadores de color y botones de gol
                _EquiposConBotonesGol(
                  partido: partido,
                  esAdmin: esAdmin,
                  golesBloc: golesBloc,
                  isProcesando: isProcesando,
                ),

                const SizedBox(height: DesignTokens.spacingS),

                // Marcador estilo estadio con realtime - Compacto
                _MarcadorEstadio(
                  golesLocal: partido.golesLocal,
                  golesVisitante: partido.golesVisitante,
                  colorBorde: colorEstado,
                  partidoId: partido.id,
                  equipoLocalColor: partido.equipoLocal.color.name,
                ),

                const SizedBox(height: DesignTokens.spacingS),

                // Display de horarios - Compacto
                _HorarioDisplay(
                  horaInicio: partido.horaInicioFormato,
                  horaFinEstimada: partido.horaFinEstimadaFormato,
                  tiempoExtra: estadoReal == _EstadoPartidoVisual.tiempoExtra,
                ),

                // Botones de accion (solo admin) - Sin boton de gol, ahora estan arriba
                if (esAdmin) ...[
                  const SizedBox(height: DesignTokens.spacingS),
                  _BotonesAccion(
                    partido: partido,
                    puedePausar: puedePausar,
                    puedeReanudar: puedeReanudar,
                    isProcesando: isProcesando,
                    onAnotarGol: null, // Ya no se usa, botones de gol estan arriba
                    onFinalizarPartido: onFinalizarPartido,
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

/// Header con badge de estado pulsante
class _HeaderEstadoPartido extends StatefulWidget {
  final _EstadoPartidoVisual estado;
  final String? tiempoTranscurrido;
  final int duracionMinutos;
  final bool enTiempoExtra;
  final int tiempoExtraSegundos;
  final VoidCallback? onPantallaCompleta;

  const _HeaderEstadoPartido({
    required this.estado,
    this.tiempoTranscurrido,
    required this.duracionMinutos,
    this.enTiempoExtra = false,
    this.tiempoExtraSegundos = 0,
    this.onPantallaCompleta,
  });

  @override
  State<_HeaderEstadoPartido> createState() => _HeaderEstadoPartidoState();
}

class _HeaderEstadoPartidoState extends State<_HeaderEstadoPartido>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Solo animar si esta en vivo o tiempo extra
    if (widget.estado == _EstadoPartidoVisual.enVivo ||
        widget.estado == _EstadoPartidoVisual.tiempoExtra) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_HeaderEstadoPartido oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.estado != oldWidget.estado) {
      if (widget.estado == _EstadoPartidoVisual.enVivo ||
          widget.estado == _EstadoPartidoVisual.tiempoExtra) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _colorEstado {
    switch (widget.estado) {
      case _EstadoPartidoVisual.enVivo:
        return DesignTokens.successColor;
      case _EstadoPartidoVisual.pausado:
        return DesignTokens.accentColor;
      case _EstadoPartidoVisual.tiempoExtra:
        return DesignTokens.errorColor;
    }
  }

  /// Formatea duracion en minutos a "MM:00"
  String _formatearDuracion(int minutos) {
    return '${minutos.toString().padLeft(2, '0')}:00';
  }

  /// Formatea segundos a "MM:SS"
  String _formatearSegundos(int segundos) {
    final mins = segundos ~/ 60;
    final segs = segundos % 60;
    return '${mins.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  String get _textoEstado {
    switch (widget.estado) {
      case _EstadoPartidoVisual.enVivo:
        return 'EN VIVO';
      case _EstadoPartidoVisual.pausado:
        return 'PAUSADO';
      case _EstadoPartidoVisual.tiempoExtra:
        return 'TIEMPO EXTRA';
    }
  }

  IconData get _iconoEstado {
    switch (widget.estado) {
      case _EstadoPartidoVisual.enVivo:
        return Icons.play_circle;
      case _EstadoPartidoVisual.pausado:
        return Icons.pause_circle;
      case _EstadoPartidoVisual.tiempoExtra:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _colorEstado,
            _colorEstado.withValues(alpha: 0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          // Badge pulsante con estado
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indicador pulsante
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingXs),
                      Icon(
                        _iconoEstado,
                        color: Colors.white,
                        size: DesignTokens.iconSizeS,
                      ),
                      const SizedBox(width: DesignTokens.spacingXs),
                      Text(
                        _textoEstado,
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: DesignTokens.fontWeightBold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // Tiempo transcurrido (formato: MM:SS normal, o duracion + badge extra)
          if (widget.tiempoTranscurrido != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXs,
              ),
              decoration: BoxDecoration(
                color: widget.enTiempoExtra
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Si es tiempo extra: mostrar duracion maxima como tiempo principal
                  // Si es normal: mostrar tiempo transcurrido
                  Text(
                    widget.enTiempoExtra
                        ? _formatearDuracion(widget.duracionMinutos)
                        : widget.tiempoTranscurrido!,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: DesignTokens.fontWeightBold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingXs),
                  Icon(
                    widget.estado == _EstadoPartidoVisual.pausado
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: DesignTokens.iconSizeS,
                  ),
                ],
              ),
            ),
            // Badge de tiempo extra separado
            if (widget.enTiempoExtra) ...[
              const SizedBox(width: DesignTokens.spacingXs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.errorColor,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  '+${_formatearSegundos(widget.tiempoExtraSegundos)} EXTRA',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],

          // Boton pantalla completa
          if (widget.onPantallaCompleta != null) ...[
            const SizedBox(width: DesignTokens.spacingS),
            IconButton(
              onPressed: widget.onPantallaCompleta,
              icon: const Icon(Icons.fullscreen),
              color: Colors.white,
              tooltip: 'Pantalla completa',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Display de equipos enfrentados con circulos de color y botones de gol
/// Nuevo diseno: Cada equipo tiene su propio boton de gol debajo
class _EquiposConBotonesGol extends StatelessWidget {
  final PartidoModel partido;
  final bool esAdmin;
  final GolesBloc? golesBloc;
  final bool isProcesando;

  const _EquiposConBotonesGol({
    required this.partido,
    required this.esAdmin,
    this.golesBloc,
    this.isProcesando = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Determinar si se pueden registrar goles
    final puedeRegistrarGoles = esAdmin && golesBloc != null && !isProcesando;

    return Row(
      children: [
        // Equipo Local con boton de gol
        Expanded(
          child: _EquipoConBotonGol(
            color: partido.equipoLocal.color,
            etiqueta: 'Local',
            partido: partido,
            esLocal: true,
            puedeRegistrar: puedeRegistrarGoles,
            golesBloc: golesBloc,
          ),
        ),

        // VS central
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
          child: Text(
            'VS',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              letterSpacing: 2,
            ),
          ),
        ),

        // Equipo Visitante con boton de gol
        Expanded(
          child: _EquipoConBotonGol(
            color: partido.equipoVisitante.color,
            etiqueta: 'Visitante',
            partido: partido,
            esLocal: false,
            puedeRegistrar: puedeRegistrarGoles,
            golesBloc: golesBloc,
          ),
        ),
      ],
    );
  }
}

/// Indicador de equipo con boton de gol integrado
class _EquipoConBotonGol extends StatelessWidget {
  final ColorEquipo color;
  final String etiqueta;
  final PartidoModel partido;
  final bool esLocal;
  final bool puedeRegistrar;
  final GolesBloc? golesBloc;

  const _EquipoConBotonGol({
    required this.color,
    required this.etiqueta,
    required this.partido,
    required this.esLocal,
    required this.puedeRegistrar,
    this.golesBloc,
  });

  void _mostrarDialogGol(BuildContext context) {
    if (golesBloc == null) return;

    final equipoQueAnota = esLocal
        ? partido.equipoLocal.color
        : partido.equipoVisitante.color;
    final equipoContrario = esLocal
        ? partido.equipoVisitante.color
        : partido.equipoLocal.color;
    final jugadores = esLocal
        ? partido.equipoLocal.jugadores
        : partido.equipoVisitante.jugadores;

    showDialog(
      context: context,
      builder: (dialogContext) => RegistrarGolDialog(
        partidoId: partido.id,
        equipoAnotador: equipoQueAnota,
        equipoContrario: equipoContrario,
        jugadores: jugadores,
        esEquipoLocal: esLocal,
        golesBloc: golesBloc!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Circulo con color del equipo - Compacto
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: color.borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.color.withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              color.displayName[0].toUpperCase(),
              style: textTheme.labelMedium?.copyWith(
                color: color.textColor,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 2),

        // Nombre del equipo - Compacto
        Text(
          color.displayName.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
            color: color.color,
            letterSpacing: 0.3,
          ),
        ),

        // Etiqueta Local/Visitante - Mas pequena
        Text(
          etiqueta,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),

        // Boton de gol (solo si puede registrar) - Compacto
        if (puedeRegistrar) ...[
          const SizedBox(height: DesignTokens.spacingXs),
          _BotonGolEquipo(
            color: color,
            onTap: () => _mostrarDialogGol(context),
          ),
        ],
      ],
    );
  }
}

/// Boton de gol estilo balon para cada equipo
class _BotonGolEquipo extends StatelessWidget {
  final ColorEquipo color;
  final VoidCallback onTap;

  const _BotonGolEquipo({
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: color.color,
      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      elevation: DesignTokens.elevationS,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        splashColor: Colors.white.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_soccer,
                color: color.textColor,
                size: 14,
              ),
              const SizedBox(width: 2),
              Text(
                '+Gol',
                style: textTheme.labelSmall?.copyWith(
                  color: color.textColor,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marcador grande estilo estadio con gradiente oscuro
/// Incluye suscripcion a Supabase Realtime para actualizaciones en tiempo real
class _MarcadorEstadio extends StatefulWidget {
  final int golesLocal;
  final int golesVisitante;
  final Color colorBorde;
  final String partidoId;
  final String equipoLocalColor;

  const _MarcadorEstadio({
    required this.golesLocal,
    required this.golesVisitante,
    required this.colorBorde,
    required this.partidoId,
    required this.equipoLocalColor,
  });

  @override
  State<_MarcadorEstadio> createState() => _MarcadorEstadioState();
}

class _MarcadorEstadioState extends State<_MarcadorEstadio> {
  /// Goles actualizados via realtime
  late int _golesLocal;
  late int _golesVisitante;

  /// Canal de Supabase Realtime
  RealtimeChannel? _golesChannel;

  /// Cliente Supabase
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _golesLocal = widget.golesLocal;
    _golesVisitante = widget.golesVisitante;
    _suscribirseRealtimeGoles();
  }

  @override
  void didUpdateWidget(_MarcadorEstadio oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincronizar si cambian los valores desde el widget padre
    if (widget.golesLocal != oldWidget.golesLocal ||
        widget.golesVisitante != oldWidget.golesVisitante) {
      _golesLocal = widget.golesLocal;
      _golesVisitante = widget.golesVisitante;
    }
  }

  @override
  void dispose() {
    if (_golesChannel != null) {
      _supabase.removeChannel(_golesChannel!);
    }
    super.dispose();
  }

  /// Suscribe a Supabase Realtime para cambios en tabla goles
  void _suscribirseRealtimeGoles() {
    _golesChannel = _supabase
        .channel('marcador_goles_${widget.partidoId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'goles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'partido_id',
            value: widget.partidoId,
          ),
          callback: (payload) {
            _recargarGoles();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'goles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'partido_id',
            value: widget.partidoId,
          ),
          callback: (payload) {
            _recargarGoles();
          },
        )
        .subscribe();
  }

  /// Recarga los goles del partido desde la base de datos
  Future<void> _recargarGoles() async {
    try {
      final response = await _supabase
          .from('goles')
          .select('equipo_anotador')
          .eq('partido_id', widget.partidoId);

      if (!mounted) return;

      int golesLocal = 0;
      int golesVisitante = 0;

      for (final gol in response) {
        final equipoAnotador = gol['equipo_anotador'] as String?;
        if (equipoAnotador?.toLowerCase() ==
            widget.equipoLocalColor.toLowerCase()) {
          golesLocal++;
        } else {
          golesVisitante++;
        }
      }

      setState(() {
        _golesLocal = golesLocal;
        _golesVisitante = golesVisitante;
      });
    } catch (e) {
      debugPrint('Error recargando goles marcador: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B263B), // Azul oscuro
            Color(0xFF0D1B2A), // Azul mas oscuro
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: widget.colorBorde,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.colorBorde.withValues(alpha: 0.2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Goles local - Compacto
          Text(
            _golesLocal.toString(),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),

          // Separador - Compacto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
            child: Text(
              '-',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Goles visitante - Compacto
          Text(
            _golesVisitante.toString(),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Display de horarios del partido - Compacto en una sola linea
class _HorarioDisplay extends StatelessWidget {
  final String? horaInicio;
  final String? horaFinEstimada;
  final bool tiempoExtra;

  const _HorarioDisplay({
    this.horaInicio,
    this.horaFinEstimada,
    this.tiempoExtra = false,
  });

  String _formatearHora(String? hora) {
    if (hora == null) return '--:--';
    if (hora.length >= 5) {
      return hora.substring(0, 5);
    }
    return hora;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: tiempoExtra
            ? Border.all(
                color: DesignTokens.errorColor.withValues(alpha: 0.5),
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge de tiempo extra si aplica
          if (tiempoExtra) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingXs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.errorColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_off,
                    size: 12,
                    color: DesignTokens.errorColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'EXTRA',
                    style: textTheme.labelSmall?.copyWith(
                      color: DesignTokens.errorColor,
                      fontWeight: DesignTokens.fontWeightBold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.spacingS),
          ],

          // Hora inicio
          Icon(
            Icons.schedule,
            size: 12,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 2),
          Text(
            _formatearHora(horaInicio),
            style: textTheme.labelMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: 'monospace',
            ),
          ),

          // Separador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingXs),
            child: Text(
              '-',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Hora fin estimada
          Icon(
            tiempoExtra ? Icons.flag : Icons.timer,
            size: 12,
            color: tiempoExtra
                ? DesignTokens.errorColor
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 2),
          Text(
            _formatearHora(horaFinEstimada),
            style: textTheme.labelMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: 'monospace',
              color: tiempoExtra ? DesignTokens.errorColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botones de accion estilo deportivo - Compactos en una linea
class _BotonesAccion extends StatelessWidget {
  final PartidoModel partido;
  final bool puedePausar;
  final bool puedeReanudar;
  final bool isProcesando;
  final void Function(PartidoModel partido)? onAnotarGol;
  final void Function(PartidoModel partido)? onFinalizarPartido;

  const _BotonesAccion({
    required this.partido,
    required this.puedePausar,
    required this.puedeReanudar,
    required this.isProcesando,
    this.onAnotarGol,
    this.onFinalizarPartido,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Boton Pausar/Reanudar
        if (puedePausar)
          _BotonAccionDeportivo(
            icono: Icons.pause,
            texto: 'Pausar',
            color: DesignTokens.accentColor,
            onPressed: isProcesando
                ? null
                : () {
                    context.read<PartidoBloc>().add(
                          PausarPartidoEvent(partidoId: partido.id),
                        );
                  },
            isProcesando: isProcesando,
          ),

        if (puedeReanudar)
          _BotonAccionDeportivo(
            icono: Icons.play_arrow,
            texto: 'Reanudar',
            color: DesignTokens.successColor,
            onPressed: isProcesando
                ? null
                : () {
                    context.read<PartidoBloc>().add(
                          ReanudarPartidoEvent(partidoId: partido.id),
                        );
                  },
            isProcesando: isProcesando,
          ),

        // Boton Anotar Gol
        if (onAnotarGol != null) ...[
          const SizedBox(width: DesignTokens.spacingXs),
          _BotonAccionDeportivo(
            icono: Icons.sports_soccer,
            texto: 'Gol',
            color: DesignTokens.primaryColor,
            onPressed: isProcesando ? null : () => onAnotarGol!(partido),
            filled: true,
          ),
        ],

        // Boton Finalizar
        if (onFinalizarPartido != null) ...[
          const SizedBox(width: DesignTokens.spacingXs),
          _BotonAccionDeportivo(
            icono: Icons.flag,
            texto: 'Finalizar',
            color: DesignTokens.errorColor,
            onPressed: isProcesando ? null : () => onFinalizarPartido!(partido),
          ),
        ],
      ],
    );
  }
}

/// Boton individual de accion con estilo deportivo - Compacto
class _BotonAccionDeportivo extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback? onPressed;
  final bool isProcesando;
  final bool filled;

  const _BotonAccionDeportivo({
    required this.icono,
    required this.texto,
    required this.color,
    this.onPressed,
    this.isProcesando = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: 4,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: textTheme.labelSmall,
        ),
        icon: isProcesando
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icono, size: 14),
        label: Text(texto),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingS,
          vertical: 4,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: textTheme.labelSmall,
      ),
      icon: isProcesando
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          : Icon(icono, size: 14),
      label: Text(texto),
    );
  }
}
