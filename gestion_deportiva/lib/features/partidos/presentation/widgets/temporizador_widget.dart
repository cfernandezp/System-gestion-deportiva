import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/alarm_service.dart';
import '../../../../core/theme/design_tokens.dart';

/// Widget de temporizador con cuenta regresiva
/// E004-HU-002: Temporizador con Alarma
///
/// Criterios de Aceptacion:
/// - CA-001: Visualizacion del tiempo en formato MM:SS
/// - CA-002: Cuenta regresiva segundo a segundo
/// - CA-005: Indicador visual de fin (pantalla roja/parpadeo)
/// - CA-006: Tiempo extra visible en negativo (-MM:SS)
///
/// Reglas de Negocio:
/// - RN-005: Alerta previa al fin (2 minutos - color amarillo)
/// - RN-006: Formato tiempo legible (MM:SS, -MM:SS)
class TemporizadorWidget extends StatefulWidget {
  /// Tiempo restante en segundos (puede ser negativo para tiempo extra)
  final int tiempoRestanteSegundos;

  /// Duracion total del partido en minutos
  final int duracionMinutos;

  /// Estado del partido (en_curso, pausado)
  final String estado;

  /// Si es true, el temporizador esta pausado
  final bool pausado;

  /// Callback cuando el tiempo cambia (cada segundo)
  final ValueChanged<int>? onTiempoCambiado;

  /// Callback cuando el tiempo llega a cero
  final VoidCallback? onTiempoTerminado;

  /// Callback cuando quedan 2 minutos
  final VoidCallback? onAdvertencia;

  /// Tamano del texto del temporizador
  final double fontSize;

  /// Si es true, muestra version compacta
  final bool compacto;

  const TemporizadorWidget({
    super.key,
    required this.tiempoRestanteSegundos,
    required this.duracionMinutos,
    this.estado = 'en_curso',
    this.pausado = false,
    this.onTiempoCambiado,
    this.onTiempoTerminado,
    this.onAdvertencia,
    this.fontSize = 56,
    this.compacto = false,
  });

  @override
  State<TemporizadorWidget> createState() => _TemporizadorWidgetState();
}

class _TemporizadorWidgetState extends State<TemporizadorWidget>
    with SingleTickerProviderStateMixin {
  /// Tiempo local que decrece cada segundo
  late int _tiempoLocal;

  /// Timer para la cuenta regresiva
  Timer? _timer;

  /// Servicio de alarmas
  final AlarmService _alarmService = AlarmService();

  /// Flag para saber si la advertencia ya fue disparada
  bool _advertenciaDisparada = false;

  /// Flag para saber si la alarma de fin ya fue disparada
  bool _alarmaFinDisparada = false;

  /// Controller para animacion de parpadeo
  late AnimationController _blinkController;

  /// Animacion de opacidad para parpadeo
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _tiempoLocal = widget.tiempoRestanteSegundos;

    // Inicializar animacion de parpadeo
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Inicializar servicio de audio
    _alarmService.initialize();

    // Iniciar timer si no esta pausado
    if (!widget.pausado && widget.estado == 'en_curso') {
      _iniciarTimer();
    }
  }

  @override
  void didUpdateWidget(TemporizadorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sincronizar tiempo si cambia desde el servidor
    if (widget.tiempoRestanteSegundos != oldWidget.tiempoRestanteSegundos) {
      _tiempoLocal = widget.tiempoRestanteSegundos;
    }

    // Manejar cambio de estado pausado
    if (widget.pausado != oldWidget.pausado) {
      if (widget.pausado) {
        _detenerTimer();
        _blinkController.stop();
      } else if (widget.estado == 'en_curso') {
        _iniciarTimer();
      }
    }

    // Manejar cambio de estado
    if (widget.estado != oldWidget.estado) {
      if (widget.estado == 'en_curso' && !widget.pausado) {
        _iniciarTimer();
      } else {
        _detenerTimer();
      }
    }
  }

  @override
  void dispose() {
    _detenerTimer();
    _blinkController.dispose();
    super.dispose();
  }

  void _iniciarTimer() {
    _detenerTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _tiempoLocal--;
        });

        widget.onTiempoCambiado?.call(_tiempoLocal);

        // RN-005: Verificar advertencia de 2 minutos
        _verificarAdvertencia();

        // CA-003: Verificar fin del tiempo
        _verificarFinTiempo();
      }
    });
  }

  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// RN-005: Alerta previa al fin
  /// Alerta visual (color amarillo) a los 2:00 minutos restantes
  /// Si duracion < 5 min, alerta al 40% del tiempo restante
  void _verificarAdvertencia() {
    if (_advertenciaDisparada) return;

    final duracionSegundos = widget.duracionMinutos * 60;
    int umbralAdvertencia;

    if (widget.duracionMinutos < 5) {
      // 40% del tiempo para partidos cortos
      umbralAdvertencia = (duracionSegundos * 0.4).round();
    } else {
      // 2 minutos para partidos normales
      umbralAdvertencia = 120;
    }

    if (_tiempoLocal <= umbralAdvertencia && _tiempoLocal > 0) {
      _advertenciaDisparada = true;
      _alarmService.playWarningBeep();
      widget.onAdvertencia?.call();
    }
  }

  /// CA-003, RN-002: Verificar fin del tiempo y disparar alarma
  void _verificarFinTiempo() {
    if (_tiempoLocal <= 0 && !_alarmaFinDisparada) {
      _alarmaFinDisparada = true;
      _alarmService.playEndAlarm();
      widget.onTiempoTerminado?.call();

      // Iniciar parpadeo cuando el tiempo termina
      _blinkController.repeat(reverse: true);
    }
  }

  /// RN-006: Formatea el tiempo en MM:SS o -MM:SS
  String _formatearTiempo() {
    final esNegativo = _tiempoLocal < 0;
    final segundosAbsolutos = _tiempoLocal.abs();
    final minutos = segundosAbsolutos ~/ 60;
    final segundos = segundosAbsolutos % 60;

    final tiempo =
        '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';

    return esNegativo ? '-$tiempo' : tiempo;
  }

  /// Determina el color segun el estado del tiempo
  /// - Normal: Verde/Blanco
  /// - Advertencia (2 min): Amarillo
  /// - Tiempo agotado: Rojo parpadeante
  Color _obtenerColorTiempo() {
    if (_tiempoLocal <= 0) {
      // CA-005: Tiempo agotado - Rojo
      return DesignTokens.errorColor;
    }

    final duracionSegundos = widget.duracionMinutos * 60;
    int umbralAdvertencia;

    if (widget.duracionMinutos < 5) {
      umbralAdvertencia = (duracionSegundos * 0.4).round();
    } else {
      umbralAdvertencia = 120;
    }

    if (_tiempoLocal <= umbralAdvertencia) {
      // RN-005: Advertencia - Amarillo/Naranja
      return DesignTokens.accentColor;
    }

    // Normal - Verde
    return DesignTokens.successColor;
  }

  @override
  Widget build(BuildContext context) {
    final colorTiempo = _obtenerColorTiempo();
    final tiempoFormateado = _formatearTiempo();
    final tiempoTerminado = _tiempoLocal <= 0;

    if (widget.compacto) {
      return _buildCompacto(colorTiempo, tiempoFormateado, tiempoTerminado);
    }

    return _buildCompleto(colorTiempo, tiempoFormateado, tiempoTerminado);
  }

  /// Version compacta del temporizador (solo numero)
  Widget _buildCompacto(
    Color colorTiempo,
    String tiempoFormateado,
    bool tiempoTerminado,
  ) {
    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        return Text(
          tiempoFormateado,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: DesignTokens.fontWeightBold,
            color: colorTiempo.withValues(
              alpha: tiempoTerminado && !widget.pausado
                  ? _blinkAnimation.value
                  : 1.0,
            ),
            fontFamily: 'monospace',
            letterSpacing: 4,
          ),
        );
      },
    );
  }

  /// Version completa del temporizador (con contenedor y etiqueta)
  Widget _buildCompleto(
    Color colorTiempo,
    String tiempoFormateado,
    bool tiempoTerminado,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        final opacidad = tiempoTerminado && !widget.pausado
            ? _blinkAnimation.value
            : 1.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingXl,
            vertical: DesignTokens.spacingM,
          ),
          decoration: BoxDecoration(
            color: colorTiempo.withValues(alpha: 0.1 * opacidad),
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: colorTiempo.withValues(alpha: 0.3 * opacidad),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Etiqueta de estado
              Text(
                _obtenerEtiqueta(),
                style: textTheme.labelSmall?.copyWith(
                  color: colorTiempo.withValues(alpha: opacidad),
                  fontWeight: DesignTokens.fontWeightMedium,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXs),

              // Tiempo grande
              Text(
                tiempoFormateado,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: colorTiempo.withValues(alpha: opacidad),
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Obtiene la etiqueta segun el estado
  String _obtenerEtiqueta() {
    if (widget.pausado) {
      return 'TIEMPO PAUSADO';
    }
    if (_tiempoLocal <= 0) {
      return 'TIEMPO EXTRA';
    }
    return 'TIEMPO RESTANTE';
  }
}
