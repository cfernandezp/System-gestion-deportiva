import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Tipos de dispositivo basados en breakpoints
enum DeviceType { mobile, tablet, desktop }

/// Widget que determina el layout segun el tamano de pantalla
/// Usa la estrategia: Mobile App Style vs Desktop Dashboard Style
///
/// Breakpoints:
/// - Mobile: < 600px
/// - Tablet: 600px - 1024px
/// - Desktop: > 1024px
class ResponsiveLayout extends StatelessWidget {
  /// Vista para dispositivos moviles (< 600px)
  /// Estilo: App nativa con BottomNavigationBar
  final Widget mobileBody;

  /// Vista para tablets (600px - 1024px)
  /// Si es null, usa desktopBody
  /// Estilo: Dashboard compacto con sidebar colapsable
  final Widget? tabletBody;

  /// Vista para desktop (> 1024px)
  /// Estilo: Dashboard completo con sidebar fijo
  final Widget desktopBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    this.tabletBody,
    required this.desktopBody,
  });

  /// Obtiene el tipo de dispositivo basado en el ancho de pantalla
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < DesignTokens.breakpointMobile) {
      return DeviceType.mobile;
    } else if (width < 1024) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Verifica si es mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Verifica si es tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Verifica si es desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Verifica si es tablet o desktop (usa dashboard layout)
  static bool isTabletOrDesktop(BuildContext context) {
    final type = getDeviceType(context);
    return type == DeviceType.tablet || type == DeviceType.desktop;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Mobile: < 600px
        if (width < DesignTokens.breakpointMobile) {
          return mobileBody;
        }

        // Tablet: 600px - 1024px
        if (width < 1024) {
          return tabletBody ?? desktopBody;
        }

        // Desktop: > 1024px
        return desktopBody;
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

  /// Verifica si es desktop
  bool get isDesktop => ResponsiveLayout.isDesktop(this);

  /// Verifica si debe usar layout de dashboard (tablet o desktop)
  bool get usesDashboardLayout => ResponsiveLayout.isTabletOrDesktop(this);
}
