import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';

/// Tipos de dispositivo basados en breakpoints
/// RN-001: Solo celular y tablet, no desktop
enum DeviceType { mobile, tablet }

/// Widget que determina el layout segun el tamano de pantalla
/// E000-HU-004: Soporte Responsive Tablet
///
/// Breakpoints (RN-001):
/// - Mobile: < 600dp (celular)
/// - Tablet: >= 600dp (tablet)
///
/// RN-002: Mobile es la experiencia principal. Tablet es mejora adicional.
/// RN-006: Fallback seguro - pantallas sin layout tablet se muestran
///          con max-width 600px centrado.
class ResponsiveLayout extends StatelessWidget {
  /// Vista para dispositivos moviles (< 600dp)
  /// Estilo: App nativa con BottomNavigationBar
  final Widget mobile;

  /// Vista para tablets (>= 600dp)
  /// Si es null, usa mobile con max-width centrado (RN-006)
  final Widget? tablet;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
  });

  /// Obtiene el tipo de dispositivo basado en el ancho de pantalla
  /// RN-001: Breakpoint unico a 600dp
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < DesignTokens.breakpointMobile) {
      return DeviceType.mobile;
    }
    return DeviceType.tablet;
  }

  /// Verifica si es mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Verifica si es tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// RN-003: Configura orientaciones segun tipo de dispositivo
  /// Celular = portrait forzado. Tablet = portrait + landscape.
  static void configureOrientations(BuildContext context) {
    if (isMobile(context)) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Mobile: < 600dp
        if (width < DesignTokens.breakpointMobile) {
          return mobile;
        }

        // Tablet: >= 600dp
        // RN-006: Si no hay layout tablet, usar mobile con max-width centrado
        if (tablet != null) {
          return tablet!;
        }

        // RN-006: Fallback seguro - mobile centrado con max-width
        // RN-008: scaffoldBackgroundColor para evitar fondo negro en tablet
        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: DesignTokens.breakpointMobile,
              ),
              child: mobile,
            ),
          ),
        );
      },
    );
  }
}

/// Extension para facilitar el acceso al tipo de dispositivo
extension ResponsiveContext on BuildContext {
  /// Obtiene el tipo de dispositivo actual
  DeviceType get deviceType => ResponsiveLayout.getDeviceType(this);

  /// Verifica si es mobile
  bool get isMobile => ResponsiveLayout.isMobile(this);

  /// Verifica si es tablet
  bool get isTablet => ResponsiveLayout.isTablet(this);
}

/// Wrapper que aplica max-width centrado automaticamente en tablet
/// Util para pantallas que no necesitan layout tablet especifico (RN-006)
class TabletSafeWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const TabletSafeWrapper({
    super.key,
    required this.child,
    this.maxWidth = DesignTokens.breakpointMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return child;
    }

    // RN-008: scaffoldBackgroundColor para evitar fondo negro en tablet
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
