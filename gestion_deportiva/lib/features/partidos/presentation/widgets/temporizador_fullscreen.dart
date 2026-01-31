import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/alarm_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/partido_model.dart';

/// Widget de temporizador en pantalla completa
/// E004-HU-002: Temporizador con Alarma
///
/// Criterios de Aceptacion:
/// - CA-009: Modo pantalla completa con letras grandes y visibles
/// - CA-010: Salir de pantalla completa al tocar/presionar boton
///
/// Reglas de Negocio:
/// - RN-008: Modo pantalla completa inmersivo
///   - Fondo oscuro para reducir distracciones
///   - Tiempo en fuente extra grande (minimo 120px)
///   - Colores de equipo visibles
///   - Score visible si hay goles registrados
/// - RN-009: Pantalla completa no bloquea funcionalidad
///   - Admin puede pausar, registrar gol y finalizar desde pantalla completa
///   - Toque simple muestra controles
class TemporizadorFullscreen extends StatefulWidget {
  /// Datos del partido actual
  final PartidoModel partido;

  /// Si el usuario es admin y puede controlar el partido
  final bool esAdmin;

  /// Goles del equipo local
  final int golesLocal;

  /// Goles del equipo visitante
  final int golesVisitante;

  /// Callback para pausar partido
  final VoidCallback? onPausar;

  /// Callback para reanudar partido
  final VoidCallback? onReanudar;

  /// Callback para registrar gol local
  final VoidCallback? onGolLocal;

  /// Callback para registrar gol visitante
  final VoidCallback? onGolVisitante;

  /// Callback para finalizar partido
  final VoidCallback? onFinalizar;

  /// Callback para salir de pantalla completa
  final VoidCallback? onSalir;

  const TemporizadorFullscreen({
    super.key,
    required this.partido,
    this.esAdmin = false,
    this.golesLocal = 0,
    this.golesVisitante = 0,
    this.onPausar,
    this.onReanudar,
    this.onGolLocal,
    this.onGolVisitante,
    this.onFinalizar,
    this.onSalir,
  });

  /// Muestra el temporizador en pantalla completa
  static Future<void> show(
    BuildContext context, {
    required PartidoModel partido,
    bool esAdmin = false,
    int golesLocal = 0,
    int golesVisitante = 0,
    VoidCallback? onPausar,
    VoidCallback? onReanudar,
    VoidCallback? onGolLocal,
    VoidCallback? onGolVisitante,
    VoidCallback? onFinalizar,
  }) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return TemporizadorFullscreen(
            partido: partido,
            esAdmin: esAdmin,
            golesLocal: golesLocal,
            golesVisitante: golesVisitante,
            onPausar: onPausar,
            onReanudar: onReanudar,
            onGolLocal: onGolLocal,
            onGolVisitante: onGolVisitante,
            onFinalizar: onFinalizar,
            onSalir: () => Navigator.of(context).pop(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  State<TemporizadorFullscreen> createState() => _TemporizadorFullscreenState();
}

class _TemporizadorFullscreenState extends State<TemporizadorFullscreen>
    with SingleTickerProviderStateMixin {
  /// Tiempo local que decrece
  late int _tiempoLocal;

  /// Timer para cuenta regresiva
  Timer? _timer;

  /// Servicio de alarmas
  final AlarmService _alarmService = AlarmService();

  /// Flag para mostrar controles (ocultos por defecto)
  bool _mostrarControles = false;

  /// Timer para ocultar controles automaticamente
  Timer? _ocultarControlesTimer;

  /// Controller para animacion de parpadeo
  late AnimationController _blinkController;

  /// Animacion de parpadeo
  late Animation<double> _blinkAnimation;

  /// Flag si la alarma de fin ya sono
  bool _alarmaFinSono = false;

  /// Flag si el beep de advertencia ya sono
  bool _advertenciaSono = false;

  @override
  void initState() {
    super.initState();

    // Sincronizar tiempo inicial
    _tiempoLocal = widget.partido.tiempoRestanteSegundos;

    // Inicializar animacion de parpadeo
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Inicializar audio
    _alarmService.initialize();

    // Entrar en modo pantalla completa
    _entrarPantallaCompleta();

    // Iniciar timer si el partido esta en curso
    if (widget.partido.estado.name == 'enCurso') {
      _iniciarTimer();
    }

    // Si ya termino el tiempo, iniciar parpadeo
    if (_tiempoLocal <= 0) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TemporizadorFullscreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sincronizar tiempo si cambia
    if (widget.partido.tiempoRestanteSegundos !=
        oldWidget.partido.tiempoRestanteSegundos) {
      _tiempoLocal = widget.partido.tiempoRestanteSegundos;
    }

    // Manejar cambio de estado
    final estadoActual = widget.partido.estado.name;
    final estadoAnterior = oldWidget.partido.estado.name;

    if (estadoActual != estadoAnterior) {
      if (estadoActual == 'enCurso') {
        _iniciarTimer();
      } else {
        _detenerTimer();
      }
    }
  }

  @override
  void dispose() {
    _detenerTimer();
    _ocultarControlesTimer?.cancel();
    _blinkController.dispose();
    _alarmService.stopEndAlarm();
    _salirPantallaCompleta();
    super.dispose();
  }

  void _entrarPantallaCompleta() {
    // Ocultar barras del sistema
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _salirPantallaCompleta() {
    // Restaurar barras del sistema
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  void _iniciarTimer() {
    _detenerTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _tiempoLocal--;
        });

        _verificarAdvertencia();
        _verificarFinTiempo();
      }
    });
  }

  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// RN-005: Beep de advertencia a los 2 minutos
  void _verificarAdvertencia() {
    if (_advertenciaSono) return;

    final duracionSegundos = widget.partido.duracionMinutos * 60;
    int umbral;

    if (widget.partido.duracionMinutos < 5) {
      umbral = (duracionSegundos * 0.4).round();
    } else {
      umbral = 120;
    }

    if (_tiempoLocal <= umbral && _tiempoLocal > 0) {
      _advertenciaSono = true;
      _alarmService.playWarningBeep();
    }
  }

  /// CA-003: Alarma al finalizar
  void _verificarFinTiempo() {
    if (_tiempoLocal <= 0 && !_alarmaFinSono) {
      _alarmaFinSono = true;
      _alarmService.playEndAlarm();
      _blinkController.repeat(reverse: true);
    }
  }

  /// RN-006: Formato MM:SS o -MM:SS
  String _formatearTiempo() {
    final esNegativo = _tiempoLocal < 0;
    final segundosAbsolutos = _tiempoLocal.abs();
    final minutos = segundosAbsolutos ~/ 60;
    final segundos = segundosAbsolutos % 60;

    final tiempo =
        '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';

    return esNegativo ? '-$tiempo' : tiempo;
  }

  /// Obtener color segun estado del tiempo
  Color _obtenerColorTiempo() {
    if (_tiempoLocal <= 0) {
      return DesignTokens.errorColor;
    }

    final duracionSegundos = widget.partido.duracionMinutos * 60;
    int umbral;

    if (widget.partido.duracionMinutos < 5) {
      umbral = (duracionSegundos * 0.4).round();
    } else {
      umbral = 120;
    }

    if (_tiempoLocal <= umbral) {
      return DesignTokens.accentColor;
    }

    return Colors.white;
  }

  /// RN-009: Mostrar controles al tocar
  void _toggleControles() {
    setState(() {
      _mostrarControles = !_mostrarControles;
    });

    // Auto-ocultar controles despues de 5 segundos
    _ocultarControlesTimer?.cancel();
    if (_mostrarControles) {
      _ocultarControlesTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _mostrarControles = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiempoFormateado = _formatearTiempo();
    final colorTiempo = _obtenerColorTiempo();
    final tiempoTerminado = _tiempoLocal <= 0;
    final estaPausado = widget.partido.estado.name == 'pausado';

    return Scaffold(
      // RN-008: Fondo oscuro
      backgroundColor: const Color(0xFF1A1A1A),
      body: GestureDetector(
        // RN-009: Toque simple muestra controles
        onTap: _toggleControles,
        // CA-010: Toque largo o boton sale de pantalla completa
        onLongPress: () {
          _alarmService.stopEndAlarm();
          widget.onSalir?.call();
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Contenido principal
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Equipos con colores
                    _buildEquiposDisplay(),

                    const SizedBox(height: DesignTokens.spacingXl),

                    // Score si hay goles
                    if (widget.golesLocal > 0 || widget.golesVisitante > 0)
                      _buildScoreDisplay(),

                    const SizedBox(height: DesignTokens.spacingXl),

                    // RN-008: Tiempo en fuente extra grande (minimo 120px)
                    AnimatedBuilder(
                      animation: _blinkAnimation,
                      builder: (context, child) {
                        final opacidad =
                            tiempoTerminado && !estaPausado
                                ? _blinkAnimation.value
                                : 1.0;

                        return Text(
                          tiempoFormateado,
                          style: TextStyle(
                            fontSize: 120, // RN-008: minimo 120px
                            fontWeight: FontWeight.bold,
                            color: colorTiempo.withValues(alpha: opacidad),
                            fontFamily: 'monospace',
                            letterSpacing: 8,
                            shadows: [
                              Shadow(
                                color: colorTiempo.withValues(alpha: 0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: DesignTokens.spacingM),

                    // Estado del partido
                    _buildEstadoChip(estaPausado, tiempoTerminado),
                  ],
                ),
              ),

              // RN-009: Controles de admin (visibles al tocar)
              if (_mostrarControles)
                _buildControles(estaPausado, tiempoTerminado),

              // Boton de salir siempre visible en esquina
              Positioned(
                top: DesignTokens.spacingM,
                right: DesignTokens.spacingM,
                child: IconButton(
                  onPressed: () {
                    _alarmService.stopEndAlarm();
                    widget.onSalir?.call();
                  },
                  icon: const Icon(Icons.close),
                  color: Colors.white54,
                  iconSize: 32,
                  tooltip: 'Salir de pantalla completa',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Display de equipos con sus colores
  Widget _buildEquiposDisplay() {
    final equipoLocal = widget.partido.equipoLocal.color;
    final equipoVisitante = widget.partido.equipoVisitante.color;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Equipo local
        _buildEquipoChip(equipoLocal, 'LOCAL'),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
          child: Text(
            'VS',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
            ),
          ),
        ),

        // Equipo visitante
        _buildEquipoChip(equipoVisitante, 'VISITANTE'),
      ],
    );
  }

  /// Chip de equipo con color
  Widget _buildEquipoChip(ColorEquipo color, String label) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: color.borderColor,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: color.color.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              color.displayName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color.textColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Text(
          color.displayName.toUpperCase(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color.color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  /// Display del score
  Widget _buildScoreDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${widget.golesLocal}',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: widget.partido.equipoLocal.color.color,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
          child: Text(
            '-',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
            ),
          ),
        ),
        Text(
          '${widget.golesVisitante}',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: widget.partido.equipoVisitante.color.color,
          ),
        ),
      ],
    );
  }

  /// Chip de estado del partido
  Widget _buildEstadoChip(bool estaPausado, bool tiempoTerminado) {
    String texto;
    Color color;

    if (estaPausado) {
      texto = 'PAUSADO';
      color = DesignTokens.accentColor;
    } else if (tiempoTerminado) {
      texto = 'TIEMPO EXTRA';
      color = DesignTokens.errorColor;
    } else {
      texto = 'EN CURSO';
      color = DesignTokens.successColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            estaPausado
                ? Icons.pause_circle
                : tiempoTerminado
                    ? Icons.flag
                    : Icons.play_circle,
            color: color,
            size: 24,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Text(
            texto,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// RN-009: Controles de admin
  Widget _buildControles(bool estaPausado, bool tiempoTerminado) {
    if (!widget.esAdmin) return const SizedBox.shrink();

    return Positioned(
      bottom: DesignTokens.spacingXl,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _mostrarControles ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botones de gol
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gol local
                  _ControlButton(
                    label: 'GOL ${widget.partido.equipoLocal.color.displayName.toUpperCase()}',
                    icon: Icons.sports_soccer,
                    color: widget.partido.equipoLocal.color.color,
                    onPressed: widget.onGolLocal,
                  ),

                  // Gol visitante
                  _ControlButton(
                    label: 'GOL ${widget.partido.equipoVisitante.color.displayName.toUpperCase()}',
                    icon: Icons.sports_soccer,
                    color: widget.partido.equipoVisitante.color.color,
                    onPressed: widget.onGolVisitante,
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.spacingM),

              // Botones de control
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pausar/Reanudar
                  if (estaPausado)
                    _ControlButton(
                      label: 'REANUDAR',
                      icon: Icons.play_arrow,
                      color: DesignTokens.successColor,
                      onPressed: widget.onReanudar,
                    )
                  else if (!tiempoTerminado)
                    _ControlButton(
                      label: 'PAUSAR',
                      icon: Icons.pause,
                      color: DesignTokens.accentColor,
                      onPressed: widget.onPausar,
                    ),

                  // Finalizar
                  _ControlButton(
                    label: 'FINALIZAR',
                    icon: Icons.flag,
                    color: DesignTokens.errorColor,
                    onPressed: () {
                      _alarmService.stopEndAlarm();
                      widget.onFinalizar?.call();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Boton de control para pantalla completa
class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
