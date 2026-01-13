import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Variantes disponibles para AppButton
enum AppButtonVariant {
  /// Boton principal con fondo de color primario
  primary,

  /// Boton secundario con borde
  secondary,

  /// Boton terciario solo texto
  tertiary,

  /// Boton de peligro/destructivo
  danger,

  /// Boton de exito
  success,
}

/// Tamanos disponibles para AppButton
enum AppButtonSize {
  /// Pequeno: altura 36px
  small,

  /// Mediano: altura 48px (default)
  medium,

  /// Grande: altura 56px
  large,
}

/// Boton personalizado con soporte para estados de carga
/// y variantes visuales consistentes con el Design System
class AppButton extends StatelessWidget {
  /// Constructor principal
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconPosition = IconPosition.leading,
    this.isLoading = false,
    this.isExpanded = false,
    this.loadingLabel,
  });

  /// Constructor para boton con solo icono
  const AppButton.icon({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
  })  : label = '',
        iconPosition = IconPosition.leading,
        isExpanded = false,
        loadingLabel = null;

  /// Texto del boton
  final String label;

  /// Callback al presionar
  final VoidCallback? onPressed;

  /// Variante visual
  final AppButtonVariant variant;

  /// Tamano del boton
  final AppButtonSize size;

  /// Icono opcional
  final IconData? icon;

  /// Posicion del icono
  final IconPosition iconPosition;

  /// Estado de carga
  final bool isLoading;

  /// Si el boton debe expandirse al ancho completo
  final bool isExpanded;

  /// Texto alternativo durante carga
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Resolver dimensiones
    final height = _resolveHeight();
    final padding = _resolvePadding();
    final iconSize = _resolveIconSize();

    // Resolver colores segun variante
    final (backgroundColor, foregroundColor, borderSide) =
        _resolveColors(colorScheme);

    // Contenido del boton
    Widget content = _buildContent(foregroundColor, iconSize);

    // Aplicar estado de carga
    if (isLoading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          if (loadingLabel != null || label.isNotEmpty) ...[
            const SizedBox(width: DesignTokens.spacingS),
            Text(loadingLabel ?? label),
          ],
        ],
      );
    }

    // Estilo base del boton
    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(
            alpha: DesignTokens.opacityDisabled,
          );
        }
        return backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(
            alpha: DesignTokens.opacityDisabled,
          );
        }
        return foregroundColor;
      }),
      side: borderSide != null
          ? WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return BorderSide(
                  color: colorScheme.onSurface.withValues(
                    alpha: DesignTokens.opacityDisabled,
                  ),
                );
              }
              return borderSide;
            })
          : null,
      minimumSize: WidgetStateProperty.all(
        Size(isExpanded ? double.infinity : 88, height),
      ),
      padding: WidgetStateProperty.all(padding),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
      ),
      elevation: WidgetStateProperty.all(
        variant == AppButtonVariant.primary ? DesignTokens.elevationS : 0,
      ),
    );

    // Construir boton segun variante
    Widget button;
    final isDisabled = onPressed == null || isLoading;

    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
      case AppButtonVariant.success:
        button = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: content,
        );
        break;
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: content,
        );
        break;
      case AppButtonVariant.tertiary:
        button = TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: content,
        );
        break;
    }

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildContent(Color foregroundColor, double iconSize) {
    // Solo icono
    if (label.isEmpty && icon != null) {
      return Icon(icon, size: iconSize);
    }

    // Solo texto
    if (icon == null) {
      return Text(label);
    }

    // Icono + texto
    final iconWidget = Icon(icon, size: iconSize);
    final textWidget = Text(label);
    final spacing = const SizedBox(width: DesignTokens.spacingS);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: iconPosition == IconPosition.leading
          ? [iconWidget, spacing, textWidget]
          : [textWidget, spacing, iconWidget],
    );
  }

  double _resolveHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 48;
      case AppButtonSize.large:
        return 56;
    }
  }

  EdgeInsetsGeometry _resolvePadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingXs,
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingL,
          vertical: DesignTokens.spacingS,
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingXl,
          vertical: DesignTokens.spacingM,
        );
    }
  }

  double _resolveIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return DesignTokens.iconSizeS;
      case AppButtonSize.medium:
        return DesignTokens.iconSizeM;
      case AppButtonSize.large:
        return DesignTokens.iconSizeM;
    }
  }

  (Color, Color, BorderSide?) _resolveColors(ColorScheme colorScheme) {
    switch (variant) {
      case AppButtonVariant.primary:
        return (
          colorScheme.primary,
          colorScheme.onPrimary,
          null,
        );
      case AppButtonVariant.secondary:
        return (
          Colors.transparent,
          colorScheme.primary,
          BorderSide(color: colorScheme.primary, width: 1.5),
        );
      case AppButtonVariant.tertiary:
        return (
          Colors.transparent,
          colorScheme.primary,
          null,
        );
      case AppButtonVariant.danger:
        return (
          colorScheme.error,
          colorScheme.onError,
          null,
        );
      case AppButtonVariant.success:
        return (
          DesignTokens.successColor,
          Colors.white,
          null,
        );
    }
  }
}

/// Posicion del icono en el boton
enum IconPosition {
  leading,
  trailing,
}

/// Boton de accion flotante personalizado
class AppFloatingActionButton extends StatelessWidget {
  const AppFloatingActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.isExtended = false,
    this.heroTag,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final bool isExtended;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
        heroTag: heroTag,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      heroTag: heroTag,
      child: Icon(icon),
    );
  }
}
