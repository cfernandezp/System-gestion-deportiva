import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/partido_model.dart';
import '../bloc/goles/goles.dart';

/// Widget para mostrar el marcador actual del partido
/// E004-HU-003: Registrar Gol
/// CA-001: Marcador visible con goles por equipo
/// CA-003: Actualizacion en tiempo real via GolesBloc
///
/// Formato: [EQUIPO_LOCAL] [goles] - [goles] [EQUIPO_VISITANTE]
/// Colores distintivos por equipo (ColorEquipo)
/// Numeros grandes y legibles
class MarcadorWidget extends StatefulWidget {
  /// Modelo del partido (para colores de equipos)
  final PartidoModel partido;

  /// Indica si mostrar en modo compacto
  final bool compacto;

  /// Callback cuando se toca el marcador
  final VoidCallback? onTap;

  const MarcadorWidget({
    super.key,
    required this.partido,
    this.compacto = false,
    this.onTap,
  });

  @override
  State<MarcadorWidget> createState() => _MarcadorWidgetState();
}

class _MarcadorWidgetState extends State<MarcadorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  int _ultimoGolesLocal = 0;
  int _ultimoGolesVisitante = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animarGol() {
    _animController.forward().then((_) => _animController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GolesBloc, GolesState>(
      listener: (context, state) {
        // Animar cuando hay un gol nuevo
        if (state is GolRegistrado) {
          _animarGol();
        }
        if (state is GolesLoaded) {
          // Detectar cambio en marcador
          if (state.golesLocal != _ultimoGolesLocal ||
              state.golesVisitante != _ultimoGolesVisitante) {
            _animarGol();
            _ultimoGolesLocal = state.golesLocal;
            _ultimoGolesVisitante = state.golesVisitante;
          }
        }
      },
      builder: (context, state) {
        // Obtener goles del estado
        int golesLocal = 0;
        int golesVisitante = 0;

        if (state is GolesLoaded) {
          golesLocal = state.golesLocal;
          golesVisitante = state.golesVisitante;
        } else if (state is GolesLoading) {
          golesLocal = state.marcadorPrevio?.golesLocal ?? 0;
          golesVisitante = state.marcadorPrevio?.golesVisitante ?? 0;
        } else if (state is GolesProcesando) {
          golesLocal = state.marcadorPrevio?.golesLocal ?? 0;
          golesVisitante = state.marcadorPrevio?.golesVisitante ?? 0;
        } else if (state is GolesError) {
          golesLocal = state.marcadorPrevio?.golesLocal ?? 0;
          golesVisitante = state.marcadorPrevio?.golesVisitante ?? 0;
        } else if (state is GolRegistrado) {
          golesLocal = state.marcador.golesLocal;
          golesVisitante = state.marcador.golesVisitante;
        } else if (state is GolEliminado) {
          golesLocal = state.marcador.golesLocal;
          golesVisitante = state.marcador.golesVisitante;
        }

        return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return _MarcadorContent(
                equipoLocal: widget.partido.equipoLocal.color,
                equipoVisitante: widget.partido.equipoVisitante.color,
                golesLocal: golesLocal,
                golesVisitante: golesVisitante,
                compacto: widget.compacto,
                scaleAnimation: _scaleAnimation,
                glowAnimation: _glowAnimation,
              );
            },
          ),
        );
      },
    );
  }
}

/// Contenido interno del marcador
class _MarcadorContent extends StatelessWidget {
  final ColorEquipo equipoLocal;
  final ColorEquipo equipoVisitante;
  final int golesLocal;
  final int golesVisitante;
  final bool compacto;
  final Animation<double> scaleAnimation;
  final Animation<double> glowAnimation;

  const _MarcadorContent({
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.golesLocal,
    required this.golesVisitante,
    required this.compacto,
    required this.scaleAnimation,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determinar quien va ganando
    final ganaLocal = golesLocal > golesVisitante;
    final ganaVisitante = golesVisitante > golesLocal;
    final empate = golesLocal == golesVisitante;

    // Tamanos segun modo
    final circleSize = compacto ? 40.0 : 56.0;
    final scoreFontSize = compacto ? 40.0 : 64.0;
    final separatorSize = compacto ? 24.0 : 36.0;

    return Container(
      padding: EdgeInsets.all(
        compacto ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: glowAnimation.value > 0.1
              ? DesignTokens.successColor
                  .withValues(alpha: 0.5 + (glowAnimation.value * 0.5))
              : colorScheme.outlineVariant,
          width: glowAnimation.value > 0.1 ? 2 : 1,
        ),
        boxShadow: glowAnimation.value > 0.1
            ? [
                BoxShadow(
                  color: DesignTokens.successColor
                      .withValues(alpha: 0.3 * glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : DesignTokens.shadowSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Equipo Local
          Expanded(
            child: _EquipoMarcador(
              color: equipoLocal,
              goles: golesLocal,
              esGanador: ganaLocal,
              esLocal: true,
              circleSize: circleSize,
              scoreFontSize: scoreFontSize,
              compacto: compacto,
              scaleAnimation: ganaLocal ? scaleAnimation : null,
            ),
          ),

          // Separador
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '-',
                  style: TextStyle(
                    fontSize: separatorSize,
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
            child: _EquipoMarcador(
              color: equipoVisitante,
              goles: golesVisitante,
              esGanador: ganaVisitante,
              esLocal: false,
              circleSize: circleSize,
              scoreFontSize: scoreFontSize,
              compacto: compacto,
              scaleAnimation: ganaVisitante ? scaleAnimation : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Display de un equipo con su marcador
class _EquipoMarcador extends StatelessWidget {
  final ColorEquipo color;
  final int goles;
  final bool esGanador;
  final bool esLocal;
  final double circleSize;
  final double scoreFontSize;
  final bool compacto;
  final Animation<double>? scaleAnimation;

  const _EquipoMarcador({
    required this.color,
    required this.goles,
    required this.esGanador,
    required this.esLocal,
    required this.circleSize,
    required this.scoreFontSize,
    required this.compacto,
    this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
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

        // Goles (numero grande)
        AnimatedDefaultTextStyle(
          duration: DesignTokens.animNormal,
          style: TextStyle(
            fontSize: scoreFontSize,
            fontWeight: DesignTokens.fontWeightBold,
            color: esGanador ? color.color : colorScheme.onSurface,
          ),
          child: Text(goles.toString()),
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

        // Indicador de ganador
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

    // Aplicar animacion de escala si hay
    if (scaleAnimation != null) {
      content = Transform.scale(
        scale: scaleAnimation!.value,
        child: content,
      );
    }

    return content;
  }
}
