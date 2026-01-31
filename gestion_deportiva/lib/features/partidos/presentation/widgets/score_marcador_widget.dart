import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/score_partido_model.dart';
import '../../data/models/estado_partido.dart';

/// Widget para mostrar el marcador del partido en vivo
/// E004-HU-004: Ver Score en Vivo
/// CA-001: Marcador visible (Equipo1 [goles] - [goles] Equipo2)
/// CA-002: Colores de equipo (naranja, verde, azul)
/// CA-005: Tiempo restante junto al score
/// CA-006: Indicador de equipo ganando (destacar visualmente)
/// CA-007: Empate visible
/// RN-006: Indicadores visuales de estado (verde pulsante, amarillo pausado, rojo extra)
class ScoreMarcadorWidget extends StatefulWidget {
  /// Datos del score
  final ScorePartidoModel score;

  /// Indica si mostrar el tiempo restante
  final bool mostrarTiempo;

  /// Indica si es vista compacta (para embeber en otros widgets)
  final bool compacto;

  /// Callback cuando se toca el widget
  final VoidCallback? onTap;

  const ScoreMarcadorWidget({
    super.key,
    required this.score,
    this.mostrarTiempo = true,
    this.compacto = false,
    this.onTap,
  });

  @override
  State<ScoreMarcadorWidget> createState() => _ScoreMarcadorWidgetState();
}

class _ScoreMarcadorWidgetState extends State<ScoreMarcadorWidget>
    with TickerProviderStateMixin {
  late AnimationController _golAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  // RN-006: Animacion pulsante para indicador de estado
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animacion de gol reciente
    _golAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _golAnimController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _golAnimController, curve: Curves.easeInOut),
    );

    // RN-006: Animacion pulsante continua para indicador de estado
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Iniciar pulso si el partido esta en curso
    _updatePulseAnimation();

    // Iniciar animacion si hay gol reciente
    if (widget.score.hayGolReciente) {
      _golAnimController.forward().then((_) => _golAnimController.reverse());
    }
  }

  @override
  void didUpdateWidget(ScoreMarcadorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animar cuando cambia el flag de gol reciente
    if (widget.score.hayGolReciente && !oldWidget.score.hayGolReciente) {
      _golAnimController.forward().then((_) => _golAnimController.reverse());
    }
    // Actualizar animacion de pulso si cambia el estado
    if (widget.score.estadoPartido != oldWidget.score.estadoPartido) {
      _updatePulseAnimation();
    }
  }

  void _updatePulseAnimation() {
    // Solo pulsar si el partido esta en curso
    if (widget.score.estadoPartido == EstadoPartido.enCurso) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0; // Mantener visible sin pulsar
    }
  }

  @override
  void dispose() {
    _golAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_golAnimController, _pulseController]),
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.all(
              widget.compacto ? DesignTokens.spacingM : DesignTokens.spacingL,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              border: Border.all(
                color: widget.score.hayGolReciente
                    ? DesignTokens.successColor
                        .withValues(alpha: 0.5 + (_glowAnimation.value * 0.5))
                    : colorScheme.outlineVariant,
                width: widget.score.hayGolReciente ? 2 : 1,
              ),
              boxShadow: widget.score.hayGolReciente
                  ? [
                      BoxShadow(
                        color: DesignTokens.successColor
                            .withValues(alpha: 0.3 * _glowAnimation.value),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : DesignTokens.shadowSm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // RN-006: Indicador de estado del partido
                _EstadoPartidoIndicator(
                  estado: widget.score.estadoPartido,
                  tiempoRestante: widget.score.tiempoRestanteSegundos,
                  pulseValue: _pulseAnimation.value,
                  compacto: widget.compacto,
                ),
                SizedBox(
                  height: widget.compacto
                      ? DesignTokens.spacingS
                      : DesignTokens.spacingM,
                ),

                // CA-005: Tiempo restante
                if (widget.mostrarTiempo) ...[
                  _TiempoDisplay(
                    tiempo: widget.score.tiempoRestanteDisplay,
                    tiempoSegundos: widget.score.tiempoRestanteSegundos,
                    compacto: widget.compacto,
                  ),
                  SizedBox(
                    height: widget.compacto
                        ? DesignTokens.spacingS
                        : DesignTokens.spacingM,
                  ),
                ],

                // CA-001, CA-002, CA-006, CA-007: Marcador con equipos
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _MarcadorDisplay(
                    equipoLocal: widget.score.equipoLocal.color,
                    equipoVisitante: widget.score.equipoVisitante.color,
                    scoreLocal: widget.score.scoreLocal,
                    scoreVisitante: widget.score.scoreVisitante,
                    ganaLocal: widget.score.ganaLocal,
                    ganaVisitante: widget.score.ganaVisitante,
                    empate: widget.score.empate,
                    compacto: widget.compacto,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// RN-006: Indicador visual de estado del partido
/// - Partido en curso: indicador verde pulsante
/// - Partido pausado: indicador amarillo
/// - Tiempo extra: indicador rojo
class _EstadoPartidoIndicator extends StatelessWidget {
  final EstadoPartido estado;
  final int tiempoRestante;
  final double pulseValue;
  final bool compacto;

  const _EstadoPartidoIndicator({
    required this.estado,
    required this.tiempoRestante,
    required this.pulseValue,
    required this.compacto,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Determinar color y label segun estado
    Color indicatorColor;
    String label;
    IconData icon;

    // RN-006: Tiempo extra tiene prioridad sobre estado
    if (tiempoRestante < 0) {
      indicatorColor = DesignTokens.errorColor;
      label = 'TIEMPO EXTRA';
      icon = Icons.timer_off;
    } else {
      switch (estado) {
        case EstadoPartido.enCurso:
          indicatorColor = DesignTokens.successColor;
          label = 'EN VIVO';
          icon = Icons.play_circle_filled;
        case EstadoPartido.pausado:
          indicatorColor = DesignTokens.accentColor;
          label = 'PAUSADO';
          icon = Icons.pause_circle_filled;
        case EstadoPartido.finalizado:
          indicatorColor = DesignTokens.secondaryColor;
          label = 'FINALIZADO';
          icon = Icons.flag;
        case EstadoPartido.pendiente:
          indicatorColor = DesignTokens.lightOnSurfaceVariant;
          label = 'PENDIENTE';
          icon = Icons.schedule;
        case EstadoPartido.cancelado:
          indicatorColor = DesignTokens.errorColor;
          label = 'CANCELADO';
          icon = Icons.cancel;
      }
    }

    final indicatorSize = compacto ? 8.0 : 10.0;
    final shouldPulse = estado == EstadoPartido.enCurso && tiempoRestante >= 0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
        vertical: compacto ? DesignTokens.spacingXs : DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(
          color: indicatorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circulo pulsante
          Container(
            width: indicatorSize,
            height: indicatorSize,
            decoration: BoxDecoration(
              color: indicatorColor.withValues(
                alpha: shouldPulse ? pulseValue : 1.0,
              ),
              shape: BoxShape.circle,
              boxShadow: shouldPulse
                  ? [
                      BoxShadow(
                        color: indicatorColor.withValues(alpha: 0.5 * pulseValue),
                        blurRadius: 6 * pulseValue,
                        spreadRadius: 1 * pulseValue,
                      ),
                    ]
                  : null,
            ),
          ),
          SizedBox(width: compacto ? DesignTokens.spacingXs : DesignTokens.spacingS),
          Icon(
            icon,
            size: compacto ? 12 : 16,
            color: indicatorColor,
          ),
          SizedBox(width: compacto ? DesignTokens.spacingXxs : DesignTokens.spacingXs),
          Text(
            label,
            style: (compacto ? textTheme.labelSmall : textTheme.labelMedium)?.copyWith(
              color: indicatorColor,
              fontWeight: DesignTokens.fontWeightBold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Display del tiempo restante
class _TiempoDisplay extends StatelessWidget {
  final String tiempo;
  final int tiempoSegundos;
  final bool compacto;

  const _TiempoDisplay({
    required this.tiempo,
    required this.tiempoSegundos,
    required this.compacto,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Determinar color segun tiempo
    Color tiempoColor;
    String label;
    if (tiempoSegundos < 0) {
      tiempoColor = DesignTokens.errorColor;
      label = 'TIEMPO EXTRA';
    } else if (tiempoSegundos <= 120) {
      tiempoColor = DesignTokens.accentColor;
      label = 'TIEMPO';
    } else {
      tiempoColor = DesignTokens.successColor;
      label = 'TIEMPO';
    }

    return Column(
      children: [
        Text(
          label,
          style: (compacto ? textTheme.labelSmall : textTheme.labelMedium)
              ?.copyWith(
            color: tiempoColor,
            fontWeight: DesignTokens.fontWeightMedium,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
            vertical: compacto ? DesignTokens.spacingXs : DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: tiempoColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: tiempoColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            tiempo,
            style: TextStyle(
              fontSize: compacto ? 20 : 28,
              fontWeight: DesignTokens.fontWeightBold,
              color: tiempoColor,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Display del marcador con equipos
/// CA-001: Marcador visible
/// CA-002: Colores de equipo
/// CA-006: Indicador equipo ganando
/// CA-007: Empate visible
class _MarcadorDisplay extends StatelessWidget {
  final ColorEquipo equipoLocal;
  final ColorEquipo equipoVisitante;
  final int scoreLocal;
  final int scoreVisitante;
  final bool ganaLocal;
  final bool ganaVisitante;
  final bool empate;
  final bool compacto;

  const _MarcadorDisplay({
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.scoreLocal,
    required this.scoreVisitante,
    required this.ganaLocal,
    required this.ganaVisitante,
    required this.empate,
    required this.compacto,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Equipo Local
        Expanded(
          child: _EquipoScoreDisplay(
            color: equipoLocal,
            score: scoreLocal,
            esGanador: ganaLocal,
            esLocal: true,
            compacto: compacto,
          ),
        ),

        // Separador VS o guion
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal:
                compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
          ),
          child: Column(
            children: [
              Text(
                '-',
                style: TextStyle(
                  fontSize: compacto ? 32 : 48,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (empate && !compacto)
                Container(
                  margin: const EdgeInsets.only(top: DesignTokens.spacingXs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Text(
                    'EMPATE',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: DesignTokens.fontWeightMedium,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Equipo Visitante
        Expanded(
          child: _EquipoScoreDisplay(
            color: equipoVisitante,
            score: scoreVisitante,
            esGanador: ganaVisitante,
            esLocal: false,
            compacto: compacto,
          ),
        ),
      ],
    );
  }
}

/// Display de equipo con su score
/// CA-002: Color de equipo
/// CA-006: Destacar visualmente si esta ganando
class _EquipoScoreDisplay extends StatelessWidget {
  final ColorEquipo color;
  final int score;
  final bool esGanador;
  final bool esLocal;
  final bool compacto;

  const _EquipoScoreDisplay({
    required this.color,
    required this.score,
    required this.esGanador,
    required this.esLocal,
    required this.compacto,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Tamanos segun modo compacto
    final circleSize = compacto ? 40.0 : 56.0;
    final scoreFontSize = compacto ? 36.0 : 48.0;

    return Column(
      children: [
        // Circulo de color del equipo
        AnimatedContainer(
          duration: DesignTokens.animNormal,
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: color.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: esGanador ? DesignTokens.successColor : color.borderColor,
              width: esGanador ? 3 : 2,
            ),
            boxShadow: esGanador
                ? [
                    BoxShadow(
                      color: DesignTokens.successColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : DesignTokens.shadowSm,
          ),
          child: Center(
            child: Text(
              color.displayName[0].toUpperCase(),
              style: TextStyle(
                color: color.textColor,
                fontSize: compacto ? 16 : 20,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
          ),
        ),

        SizedBox(height: compacto ? DesignTokens.spacingXs : DesignTokens.spacingS),

        // Score
        AnimatedDefaultTextStyle(
          duration: DesignTokens.animNormal,
          style: TextStyle(
            fontSize: scoreFontSize,
            fontWeight: DesignTokens.fontWeightBold,
            color: esGanador ? color.color : colorScheme.onSurface,
          ),
          child: Text(score.toString()),
        ),

        // Nombre del equipo
        Text(
          color.displayName.toUpperCase(),
          style: (compacto ? textTheme.labelSmall : textTheme.labelMedium)
              ?.copyWith(
            color: esGanador ? color.color : colorScheme.onSurfaceVariant,
            fontWeight:
                esGanador ? DesignTokens.fontWeightBold : DesignTokens.fontWeightMedium,
          ),
        ),

        // Etiqueta Local/Visitante
        if (!compacto)
          Text(
            esLocal ? 'Local' : 'Visitante',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),

        // CA-006: Indicador de ganador
        if (esGanador && !compacto)
          Container(
            margin: const EdgeInsets.only(top: DesignTokens.spacingXs),
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXxs,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.successColor,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  'GANANDO',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
