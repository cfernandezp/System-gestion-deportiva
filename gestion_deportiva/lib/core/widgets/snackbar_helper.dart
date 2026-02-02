import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Helper centralizado para mostrar SnackBars con estilos consistentes
/// Garantiza que el texto sea siempre legible sobre fondos de colores
class SnackBarHelper {
  SnackBarHelper._();

  /// Muestra un SnackBar de error con texto blanco sobre fondo rojo
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.errorColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Muestra un SnackBar de exito con texto blanco sobre fondo verde
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.successColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Muestra un SnackBar de advertencia con texto blanco sobre fondo naranja
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.accentColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Muestra un SnackBar informativo usando los colores del tema
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.onInverseSurface),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onInverseSurface),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Crea un SnackBarAction con texto blanco para usar en snackbars de error
  static SnackBarAction createWhiteAction({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SnackBarAction(
      label: label,
      textColor: Colors.white,
      onPressed: onPressed,
    );
  }
}
