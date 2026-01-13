import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/app_colors.dart';

/// Tipos de badge predefinidos para estados deportivos
enum StatusBadgeType {
  /// Victoria - Verde
  victoria,

  /// Derrota - Rojo
  derrota,

  /// Empate - Gris
  empate,

  /// En curso - Naranja
  enCurso,

  /// Finalizado - Verde
  finalizado,

  /// Programado - Azul
  programado,

  /// Cancelado - Gris oscuro
  cancelado,

  /// Activo - Verde
  activo,

  /// Inactivo - Gris
  inactivo,

  /// Personalizado - Color custom
  custom,
}

/// Tamano del badge
enum StatusBadgeSize {
  /// Pequeno - para listas compactas
  small,

  /// Mediano - uso general
  medium,

  /// Grande - para destacar
  large,
}

/// Badge de estado para mostrar estados de partidos, jugadores, etc.
/// Usa colores semanticos del Design System
class StatusBadge extends StatelessWidget {
  /// Constructor principal
  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.custom,
    this.size = StatusBadgeSize.medium,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.outlined = false,
  });

  /// Constructor para victoria
  const StatusBadge.victoria({
    super.key,
    this.label = 'Victoria',
    this.size = StatusBadgeSize.medium,
    this.icon,
    this.outlined = false,
  })  : type = StatusBadgeType.victoria,
        backgroundColor = null,
        textColor = null;

  /// Constructor para derrota
  const StatusBadge.derrota({
    super.key,
    this.label = 'Derrota',
    this.size = StatusBadgeSize.medium,
    this.icon,
    this.outlined = false,
  })  : type = StatusBadgeType.derrota,
        backgroundColor = null,
        textColor = null;

  /// Constructor para empate
  const StatusBadge.empate({
    super.key,
    this.label = 'Empate',
    this.size = StatusBadgeSize.medium,
    this.icon,
    this.outlined = false,
  })  : type = StatusBadgeType.empate,
        backgroundColor = null,
        textColor = null;

  /// Constructor para en curso
  const StatusBadge.enCurso({
    super.key,
    this.label = 'En curso',
    this.size = StatusBadgeSize.medium,
    this.icon,
    this.outlined = false,
  })  : type = StatusBadgeType.enCurso,
        backgroundColor = null,
        textColor = null;

  /// Constructor para finalizado
  const StatusBadge.finalizado({
    super.key,
    this.label = 'Finalizado',
    this.size = StatusBadgeSize.medium,
    this.icon,
    this.outlined = false,
  })  : type = StatusBadgeType.finalizado,
        backgroundColor = null,
        textColor = null;

  /// Constructor para programado
  const StatusBadge.programado({
    super.key,
    this.label = 'Programado',
    this.size = StatusBadgeSize.medium,
    this.icon,
    this.outlined = false,
  })  : type = StatusBadgeType.programado,
        backgroundColor = null,
        textColor = null;

  /// Constructor para activo
  const StatusBadge.activo({
    super.key,
    this.label = 'Activo',
    this.size = StatusBadgeSize.medium,
    this.icon,
    this.outlined = false,
  })  : type = StatusBadgeType.activo,
        backgroundColor = null,
        textColor = null;

  /// Constructor para inactivo
  const StatusBadge.inactivo({
    super.key,
    this.label = 'Inactivo',
    this.size = StatusBadgeSize.medium,
    this.icon,
    this.outlined = false,
  })  : type = StatusBadgeType.inactivo,
        backgroundColor = null,
        textColor = null;

  /// Texto del badge
  final String label;

  /// Tipo predefinido del badge
  final StatusBadgeType type;

  /// Tamano del badge
  final StatusBadgeSize size;

  /// Color de fondo personalizado (solo para custom)
  final Color? backgroundColor;

  /// Color de texto personalizado (solo para custom)
  final Color? textColor;

  /// Icono opcional
  final IconData? icon;

  /// Si debe mostrar solo borde sin fondo
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor) = _resolveColors();
    final (paddingH, paddingV, fontSize, iconSize) = _resolveSizes();

    final effectiveBgColor = outlined ? Colors.transparent : bgColor;
    final effectiveFgColor = outlined ? bgColor : fgColor;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: outlined ? Border.all(color: bgColor, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: effectiveFgColor),
            SizedBox(width: paddingV),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: DesignTokens.fontWeightMedium,
              color: effectiveFgColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _resolveColors() {
    switch (type) {
      case StatusBadgeType.victoria:
      case StatusBadgeType.activo:
      case StatusBadgeType.finalizado:
        return (AppColors.victoria, Colors.white);
      case StatusBadgeType.derrota:
        return (AppColors.derrota, Colors.white);
      case StatusBadgeType.empate:
      case StatusBadgeType.inactivo:
        return (AppColors.empate, Colors.white);
      case StatusBadgeType.enCurso:
        return (AppColors.enCurso, Colors.white);
      case StatusBadgeType.programado:
        return (AppColors.programado, Colors.white);
      case StatusBadgeType.cancelado:
        return (AppColors.cancelado, Colors.white);
      case StatusBadgeType.custom:
        return (
          backgroundColor ?? AppColors.empate,
          textColor ?? Colors.white,
        );
    }
  }

  (double, double, double, double) _resolveSizes() {
    switch (size) {
      case StatusBadgeSize.small:
        return (
          DesignTokens.spacingS,
          DesignTokens.spacingXxs,
          DesignTokens.fontSizeXs - 1,
          DesignTokens.iconSizeS - 4,
        );
      case StatusBadgeSize.medium:
        return (
          DesignTokens.spacingM,
          DesignTokens.spacingXs,
          DesignTokens.fontSizeXs,
          DesignTokens.iconSizeS,
        );
      case StatusBadgeSize.large:
        return (
          DesignTokens.spacingM,
          DesignTokens.spacingS,
          DesignTokens.fontSizeS,
          DesignTokens.iconSizeM,
        );
    }
  }
}

/// Badge numerico para mostrar contadores, posiciones, etc.
class NumberBadge extends StatelessWidget {
  const NumberBadge({
    super.key,
    required this.number,
    this.backgroundColor,
    this.textColor,
    this.size = StatusBadgeSize.medium,
  });

  /// Constructor para posicion de ranking
  const NumberBadge.ranking({
    super.key,
    required this.number,
    this.size = StatusBadgeSize.medium,
  })  : backgroundColor = null,
        textColor = null;

  final int number;
  final Color? backgroundColor;
  final Color? textColor;
  final StatusBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Colores especiales para ranking
    Color bgColor;
    Color fgColor = Colors.white;

    if (backgroundColor != null) {
      bgColor = backgroundColor!;
      fgColor = textColor ?? Colors.white;
    } else {
      bgColor = AppColors.posicionRanking(number);
      if (number > 3) {
        bgColor = colorScheme.surfaceContainerHighest;
        fgColor = colorScheme.onSurface;
      }
    }

    final dimension = _resolveDimension();
    final fontSize = _resolveFontSize();

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: DesignTokens.fontWeightBold,
          color: fgColor,
        ),
      ),
    );
  }

  double _resolveDimension() {
    switch (size) {
      case StatusBadgeSize.small:
        return 20;
      case StatusBadgeSize.medium:
        return 28;
      case StatusBadgeSize.large:
        return 36;
    }
  }

  double _resolveFontSize() {
    switch (size) {
      case StatusBadgeSize.small:
        return DesignTokens.fontSizeXs - 2;
      case StatusBadgeSize.medium:
        return DesignTokens.fontSizeXs;
      case StatusBadgeSize.large:
        return DesignTokens.fontSizeS;
    }
  }
}

/// Badge con punto de notificacion
class DotBadge extends StatelessWidget {
  const DotBadge({
    super.key,
    required this.child,
    this.showBadge = true,
    this.count,
    this.color,
  });

  final Widget child;
  final bool showBadge;
  final int? count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!showBadge) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: count != null
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                : const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color ?? colorScheme.error,
              shape: count != null ? BoxShape.rectangle : BoxShape.circle,
              borderRadius:
                  count != null ? BorderRadius.circular(10) : null,
            ),
            constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
            child: count != null
                ? Text(
                    count! > 99 ? '99+' : count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onError,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
