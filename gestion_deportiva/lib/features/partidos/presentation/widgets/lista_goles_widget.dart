import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/gol_model.dart';

/// Widget para mostrar la lista de goles de un partido
/// E004-HU-004: Ver Score en Vivo
/// CA-004: Lista de goles (jugador, minuto, equipo)
/// RN-007: Goles recientes destacados (animacion/highlight 5 segundos)
class ListaGolesWidget extends StatelessWidget {
  /// Lista de goles ordenada por minuto
  final List<GolModel> goles;

  /// Color del equipo local (para identificar goles)
  final ColorEquipo equipoLocal;

  /// Color del equipo visitante
  final ColorEquipo equipoVisitante;

  /// Indica si mostrar en modo compacto
  final bool compacto;

  /// Altura maxima del widget (para scroll)
  final double? maxHeight;

  /// Callback cuando se toca un gol
  final void Function(GolModel gol)? onGolTap;

  const ListaGolesWidget({
    super.key,
    required this.goles,
    required this.equipoLocal,
    required this.equipoVisitante,
    this.compacto = false,
    this.maxHeight,
    this.onGolTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (goles.isEmpty) {
      return _buildEmptyState(context, colorScheme, textTheme);
    }

    final content = ListView.separated(
      shrinkWrap: true,
      physics: maxHeight != null
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(
        compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
      ),
      itemCount: goles.length,
      separatorBuilder: (_, __) => SizedBox(
        height: compacto ? DesignTokens.spacingXs : DesignTokens.spacingS,
      ),
      itemBuilder: (context, index) {
        final gol = goles[index];
        return _GolItem(
          gol: gol,
          equipoLocal: equipoLocal,
          equipoVisitante: equipoVisitante,
          compacto: compacto,
          onTap: onGolTap != null ? () => onGolTap!(gol) : null,
        );
      },
    );

    return Container(
      constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(
              compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: compacto ? 16 : 20,
                  color: colorScheme.primary,
                ),
                SizedBox(
                    width: compacto ? DesignTokens.spacingXs : DesignTokens.spacingS),
                Text(
                  'GOLES (${goles.length})',
                  style: (compacto ? textTheme.labelSmall : textTheme.labelMedium)
                      ?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                    letterSpacing: 1,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          // Lista de goles
          maxHeight != null ? Expanded(child: content) : content,
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: EdgeInsets.all(
        compacto ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_soccer_outlined,
            size: compacto ? 32 : 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(
              height: compacto ? DesignTokens.spacingXs : DesignTokens.spacingS),
          Text(
            'Sin goles',
            style: (compacto ? textTheme.bodySmall : textTheme.bodyMedium)?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (!compacto)
            Text(
              '0 - 0',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
        ],
      ),
    );
  }
}

/// Item individual de gol con animacion de highlight
/// CA-004: Minuto, nombre jugador, color equipo
/// RN-007: Goles recientes destacados (highlight 5 segundos)
class _GolItem extends StatefulWidget {
  final GolModel gol;
  final ColorEquipo equipoLocal;
  final ColorEquipo equipoVisitante;
  final bool compacto;
  final VoidCallback? onTap;

  const _GolItem({
    required this.gol,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.compacto,
    this.onTap,
  });

  @override
  State<_GolItem> createState() => _GolItemState();
}

class _GolItemState extends State<_GolItem> with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;
  bool _esReciente = false;

  @override
  void initState() {
    super.initState();

    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _highlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    _checkReciente();
  }

  @override
  void didUpdateWidget(_GolItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkReciente();
  }

  void _checkReciente() {
    final esReciente = widget.gol.createdAt != null &&
        DateTime.now().difference(widget.gol.createdAt!).inSeconds < 5;

    if (esReciente && !_esReciente) {
      // RN-007: Iniciar animacion de highlight pulsante
      _highlightController.repeat(reverse: true);
    } else if (!esReciente && _esReciente) {
      _highlightController.stop();
      _highlightController.value = 0;
    }

    _esReciente = esReciente;
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determinar color del equipo basado en equipoAnotador
    final colorEquipo = _getColorEquipo();

    return AnimatedBuilder(
      animation: _highlightController,
      builder: (context, child) {
        return InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          child: Container(
            padding: EdgeInsets.all(
              widget.compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
            ),
            decoration: BoxDecoration(
              color: _esReciente
                  ? DesignTokens.successColor
                      .withValues(alpha: 0.1 + (0.1 * _highlightAnimation.value))
                  : colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              border: Border.all(
                color: _esReciente
                    ? DesignTokens.successColor
                        .withValues(alpha: 0.5 + (0.3 * _highlightAnimation.value))
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: _esReciente ? 2 : 1,
              ),
              boxShadow: _esReciente
                  ? [
                      BoxShadow(
                        color: DesignTokens.successColor
                            .withValues(alpha: 0.2 * _highlightAnimation.value),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Minuto con estilo mejorado
                _MinutoDisplay(
                  minuto: widget.gol.minuto,
                  colorEquipo: colorEquipo,
                  compacto: widget.compacto,
                ),

                SizedBox(
                    width: widget.compacto
                        ? DesignTokens.spacingS
                        : DesignTokens.spacingM),

                // Icono de gol (diferente para autogol)
                _GolIcono(
                  esAutogol: widget.gol.esAutogol,
                  colorEquipo: colorEquipo,
                  compacto: widget.compacto,
                ),

                SizedBox(
                    width: widget.compacto
                        ? DesignTokens.spacingS
                        : DesignTokens.spacingM),

                // Nombre del jugador y equipo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.gol.jugadorNombre ?? 'Sin asignar',
                              style: (widget.compacto
                                      ? textTheme.bodySmall
                                      : textTheme.bodyMedium)
                                  ?.copyWith(
                                fontWeight: DesignTokens.fontWeightSemiBold,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // RN-007: Badge de gol reciente con animacion
                          if (_esReciente)
                            Transform.scale(
                              scale: 1.0 + (0.1 * _highlightAnimation.value),
                              child: Container(
                                margin: const EdgeInsets.only(
                                    left: DesignTokens.spacingXs),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DesignTokens.spacingXs,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: DesignTokens.successColor,
                                  borderRadius:
                                      BorderRadius.circular(DesignTokens.radiusS),
                                  boxShadow: [
                                    BoxShadow(
                                      color: DesignTokens.successColor
                                          .withValues(alpha: 0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.celebration,
                                      size: widget.compacto ? 8 : 10,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'GOL!',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: DesignTokens.fontWeightBold,
                                        fontSize: widget.compacto ? 8 : 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Indicador de color del equipo
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colorEquipo.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorEquipo.borderColor,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            colorEquipo.displayName,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorEquipo.color,
                              fontWeight: DesignTokens.fontWeightMedium,
                            ),
                          ),
                          // Indicador de autogol mejorado
                          if (widget.gol.esAutogol) ...[
                            const SizedBox(width: DesignTokens.spacingS),
                            _AutogolBadge(compacto: widget.compacto),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Obtiene el ColorEquipo basado en el string equipoAnotador
  ColorEquipo _getColorEquipo() {
    final colorString = widget.gol.equipoAnotador.toLowerCase();
    if (colorString == widget.equipoLocal.name) {
      return widget.equipoLocal;
    } else if (colorString == widget.equipoVisitante.name) {
      return widget.equipoVisitante;
    }
    // Fallback: intentar parsear directamente
    return ColorEquipo.fromString(widget.gol.equipoAnotador) ?? widget.equipoLocal;
  }
}

/// Display del minuto del gol con estilo mejorado
class _MinutoDisplay extends StatelessWidget {
  final int minuto;
  final ColorEquipo colorEquipo;
  final bool compacto;

  const _MinutoDisplay({
    required this.minuto,
    required this.colorEquipo,
    required this.compacto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compacto ? 40 : 50,
      height: compacto ? 40 : 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorEquipo.color.withValues(alpha: 0.2),
            colorEquipo.color.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorEquipo.color.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          "$minuto'",
          style: TextStyle(
            fontSize: compacto ? 14 : 16,
            fontWeight: DesignTokens.fontWeightBold,
            color: colorEquipo.color,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

/// Icono de gol con diferenciacion visual para autogol
class _GolIcono extends StatelessWidget {
  final bool esAutogol;
  final ColorEquipo colorEquipo;
  final bool compacto;

  const _GolIcono({
    required this.esAutogol,
    required this.colorEquipo,
    required this.compacto,
  });

  @override
  Widget build(BuildContext context) {
    final size = compacto ? 32.0 : 40.0;
    final iconSize = compacto ? 16.0 : 20.0;

    if (esAutogol) {
      // Autogol: icono diferente con estilo de error
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: DesignTokens.errorColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: DesignTokens.errorColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.sports_soccer,
                color: DesignTokens.errorColor,
                size: iconSize,
              ),
              // Flecha indicando direccion incorrecta
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(
                    color: DesignTokens.errorColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.south_west,
                    color: Colors.white,
                    size: compacto ? 8 : 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Gol normal
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorEquipo.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorEquipo.color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.sports_soccer,
          color: colorEquipo.textColor,
          size: iconSize,
        ),
      ),
    );
  }
}

/// Badge de autogol mejorado con icono de advertencia
class _AutogolBadge extends StatelessWidget {
  final bool compacto;

  const _AutogolBadge({required this.compacto});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? DesignTokens.spacingXs : DesignTokens.spacingS,
        vertical: compacto ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: DesignTokens.errorColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: compacto ? 10 : 12,
            color: DesignTokens.errorColor,
          ),
          const SizedBox(width: 3),
          Text(
            'AUTOGOL',
            style: textTheme.labelSmall?.copyWith(
              color: DesignTokens.errorColor,
              fontWeight: DesignTokens.fontWeightBold,
              fontSize: compacto ? 8 : 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
