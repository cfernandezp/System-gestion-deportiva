import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/app_colors.dart';

/// Variantes disponibles para AppCard
enum AppCardVariant {
  /// Card estandar con elevacion sutil
  standard,

  /// Card con mayor elevacion para destacar
  elevated,

  /// Card con borde sin elevacion
  outlined,

  /// Card con fondo del color primario
  filled,
}

/// Card personalizada que respeta el tema Light/Dark
/// Usa este widget en lugar de Card() directamente
class AppCard extends StatelessWidget {
  /// Constructor principal
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.standard,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Contenido de la card
  final Widget child;

  /// Variante visual de la card
  final AppCardVariant variant;

  /// Callback al tocar la card
  final VoidCallback? onTap;

  /// Callback al mantener presionada la card
  final VoidCallback? onLongPress;

  /// Padding interno (default: spacingM)
  final EdgeInsetsGeometry? padding;

  /// Margin externo (default: spacingS)
  final EdgeInsetsGeometry? margin;

  /// Ancho fijo (opcional)
  final double? width;

  /// Alto fijo (opcional)
  final double? height;

  /// Radio de bordes personalizado
  final BorderRadius? borderRadius;

  /// Color de fondo personalizado
  final Color? backgroundColor;

  /// Color de borde personalizado (solo para outlined)
  final Color? borderColor;

  /// Comportamiento de recorte
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppColors.isDarkMode(context);

    // Resolver colores segun variante
    final bgColor = _resolveBackgroundColor(colorScheme);
    final border = _resolveBorder(colorScheme);
    final elevation = _resolveElevation();
    final shadows = _resolveShadows(isDark);

    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(DesignTokens.radiusM);
    final effectivePadding =
        padding ?? const EdgeInsets.all(DesignTokens.spacingM);
    final effectiveMargin =
        margin ?? const EdgeInsets.all(DesignTokens.spacingS);

    Widget cardContent = Container(
      width: width,
      height: height,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: effectiveBorderRadius,
        border: border,
        boxShadow: elevation > 0 ? shadows : null,
      ),
      child: child,
    );

    // Agregar interactividad si hay callbacks
    if (onTap != null || onLongPress != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: effectiveBorderRadius,
          child: cardContent,
        ),
      );
    }

    return Padding(padding: effectiveMargin, child: cardContent);
  }

  Color _resolveBackgroundColor(ColorScheme colorScheme) {
    if (backgroundColor != null) return backgroundColor!;

    switch (variant) {
      case AppCardVariant.standard:
      case AppCardVariant.elevated:
      case AppCardVariant.outlined:
        return colorScheme.surface;
      case AppCardVariant.filled:
        return colorScheme.primaryContainer;
    }
  }

  Border? _resolveBorder(ColorScheme colorScheme) {
    if (variant == AppCardVariant.outlined) {
      return Border.all(
        color: borderColor ?? colorScheme.outline,
        width: 1,
      );
    }
    return null;
  }

  double _resolveElevation() {
    switch (variant) {
      case AppCardVariant.standard:
        return DesignTokens.elevationS;
      case AppCardVariant.elevated:
        return DesignTokens.elevationM;
      case AppCardVariant.outlined:
      case AppCardVariant.filled:
        return DesignTokens.elevation0;
    }
  }

  List<BoxShadow> _resolveShadows(bool isDark) {
    switch (variant) {
      case AppCardVariant.standard:
        return isDark ? DesignTokens.shadowSmDark : DesignTokens.shadowSm;
      case AppCardVariant.elevated:
        return isDark ? DesignTokens.shadowMdDark : DesignTokens.shadowMd;
      case AppCardVariant.outlined:
      case AppCardVariant.filled:
        return [];
    }
  }
}

/// Card especializada para mostrar informacion de partido
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.child,
    this.onTap,
    this.isHighlighted = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      variant: isHighlighted ? AppCardVariant.elevated : AppCardVariant.standard,
      onTap: onTap,
      borderColor: isHighlighted ? colorScheme.primary : null,
      child: child,
    );
  }
}

/// Card especializada para equipos
class TeamCard extends StatelessWidget {
  const TeamCard({
    super.key,
    required this.child,
    this.onTap,
    this.teamColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? teamColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outlined,
      onTap: onTap,
      borderColor: teamColor,
      child: child,
    );
  }
}
