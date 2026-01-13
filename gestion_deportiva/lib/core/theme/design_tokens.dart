import 'package:flutter/material.dart';

/// Design Tokens para el Sistema de Gestion Deportiva
/// Define las constantes de diseno usadas en toda la aplicacion
/// Estilo: Minimalista Profesional + Material You Deportivo
class DesignTokens {
  DesignTokens._();

  // ============================================
  // === COLORES BASE ===
  // ============================================

  /// Verde cesped moderno - Color principal de la marca
  static const Color primaryColor = Color(0xFF10B981);

  /// Azul profundo - Color secundario para contraste
  static const Color secondaryColor = Color(0xFF1E40AF);

  /// Naranja energia - Acentos y advertencias
  static const Color accentColor = Color(0xFFF59E0B);

  /// Rojo - Errores y estados negativos
  static const Color errorColor = Color(0xFFEF4444);

  /// Verde exito - Confirmaciones y estados positivos
  static const Color successColor = Color(0xFF22C55E);

  // ============================================
  // === COLORES LIGHT MODE ===
  // ============================================

  /// Fondo principal light - Gris muy claro
  static const Color lightBackground = Color(0xFFF8FAFC);

  /// Superficie light - Blanco puro para cards
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Superficie variante light - Gris suave
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);

  /// Texto sobre fondo light - Casi negro
  static const Color lightOnBackground = Color(0xFF0F172A);

  /// Texto sobre superficie light - Gris oscuro
  static const Color lightOnSurface = Color(0xFF1E293B);

  /// Texto secundario light - Gris medio
  static const Color lightOnSurfaceVariant = Color(0xFF64748B);

  /// Borde light - Gris claro
  static const Color lightOutline = Color(0xFFCBD5E1);

  /// Borde variante light - Gris muy claro
  static const Color lightOutlineVariant = Color(0xFFE2E8F0);

  // ============================================
  // === COLORES DARK MODE ===
  // ============================================

  /// Fondo principal dark - Azul muy oscuro
  static const Color darkBackground = Color(0xFF0F172A);

  /// Superficie dark - Azul oscuro
  static const Color darkSurface = Color(0xFF1E293B);

  /// Superficie variante dark - Gris azulado
  static const Color darkSurfaceVariant = Color(0xFF334155);

  /// Texto sobre fondo dark - Casi blanco
  static const Color darkOnBackground = Color(0xFFF8FAFC);

  /// Texto sobre superficie dark - Gris claro
  static const Color darkOnSurface = Color(0xFFE2E8F0);

  /// Texto secundario dark - Gris medio
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);

  /// Borde dark - Gris azulado
  static const Color darkOutline = Color(0xFF475569);

  /// Borde variante dark - Gris oscuro
  static const Color darkOutlineVariant = Color(0xFF334155);

  // ============================================
  // === GRADIENTES ===
  // ============================================

  /// Gradiente principal - Verde cesped
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente secundario - Azul profundo
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente dark - Para fondos oscuros
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Gradiente accent - Naranja energia
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================
  // === SPACING (Sistema 4px) ===
  // ============================================

  /// 2px - Espaciado extra extra pequeno
  static const double spacingXxs = 2.0;

  /// 4px - Espaciado extra pequeno
  static const double spacingXs = 4.0;

  /// 8px - Espaciado pequeno
  static const double spacingS = 8.0;

  /// 16px - Espaciado mediano (base)
  static const double spacingM = 16.0;

  /// 24px - Espaciado grande
  static const double spacingL = 24.0;

  /// 32px - Espaciado extra grande
  static const double spacingXl = 32.0;

  /// 48px - Espaciado extra extra grande
  static const double spacingXxl = 48.0;

  /// 64px - Espaciado maximo
  static const double spacingXxxl = 64.0;

  // ============================================
  // === BORDER RADIUS ===
  // ============================================

  /// 4px - Bordes extra pequenos
  static const double radiusXs = 4.0;

  /// 8px - Bordes pequenos
  static const double radiusS = 8.0;

  /// 12px - Bordes medianos
  static const double radiusM = 12.0;

  /// 16px - Bordes grandes
  static const double radiusL = 16.0;

  /// 24px - Bordes extra grandes
  static const double radiusXl = 24.0;

  /// Circular completo
  static const double radiusFull = 9999.0;

  // ============================================
  // === SOMBRAS LIGHT MODE ===
  // ============================================

  /// Sombra pequena light
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Sombra mediana light
  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sombra grande light
  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Sombra extra grande light
  static List<BoxShadow> get shadowXl => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  // ============================================
  // === SOMBRAS DARK MODE (mas sutiles) ===
  // ============================================

  /// Sombra pequena dark
  static List<BoxShadow> get shadowSmDark => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Sombra mediana dark
  static List<BoxShadow> get shadowMdDark => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sombra grande dark
  static List<BoxShadow> get shadowLgDark => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // ============================================
  // === TIPOGRAFIA ===
  // ============================================

  /// Familia de fuente principal
  static const String fontFamily = 'Inter';

  /// 12px - Texto extra pequeno (captions, badges)
  static const double fontSizeXs = 12.0;

  /// 14px - Texto pequeno (body small, labels)
  static const double fontSizeS = 14.0;

  /// 16px - Texto mediano (body, base)
  static const double fontSizeM = 16.0;

  /// 18px - Texto grande (subtitulos)
  static const double fontSizeL = 18.0;

  /// 20px - Texto extra grande (titulos pequenos)
  static const double fontSizeXl = 20.0;

  /// 24px - Texto titulo (titulos medianos)
  static const double fontSizeXxl = 24.0;

  /// 32px - Texto display (titulos grandes)
  static const double fontSizeDisplay = 32.0;

  /// 40px - Texto hero (titulos principales)
  static const double fontSizeHero = 40.0;

  // ============================================
  // === PESOS DE FUENTE ===
  // ============================================

  /// Peso normal
  static const FontWeight fontWeightRegular = FontWeight.w400;

  /// Peso medio
  static const FontWeight fontWeightMedium = FontWeight.w500;

  /// Peso semi-bold
  static const FontWeight fontWeightSemiBold = FontWeight.w600;

  /// Peso bold
  static const FontWeight fontWeightBold = FontWeight.w700;

  // ============================================
  // === ANIMACIONES ===
  // ============================================

  /// 150ms - Animacion rapida (hovers, toggles)
  static const Duration animFast = Duration(milliseconds: 150);

  /// 300ms - Animacion normal (transiciones)
  static const Duration animNormal = Duration(milliseconds: 300);

  /// 500ms - Animacion lenta (modales, overlays)
  static const Duration animSlow = Duration(milliseconds: 500);

  /// 800ms - Animacion muy lenta (splash, hero)
  static const Duration animVerySlow = Duration(milliseconds: 800);

  /// Curva de animacion por defecto
  static const Curve animCurve = Curves.easeInOut;

  /// Curva de animacion de entrada
  static const Curve animCurveIn = Curves.easeIn;

  /// Curva de animacion de salida
  static const Curve animCurveOut = Curves.easeOut;

  /// Curva de rebote
  static const Curve animCurveBounce = Curves.elasticOut;

  // ============================================
  // === BREAKPOINTS ===
  // ============================================

  /// Ancho maximo para mobile
  static const double breakpointMobile = 600.0;

  /// Ancho maximo para tablet
  static const double breakpointTablet = 900.0;

  /// Ancho minimo para desktop
  static const double breakpointDesktop = 1200.0;

  /// Ancho maximo de contenido
  static const double maxContentWidth = 1440.0;

  // ============================================
  // === ICONOS TAMANOS ===
  // ============================================

  /// 16px - Iconos pequenos (inline, badges)
  static const double iconSizeS = 16.0;

  /// 24px - Iconos medianos (botones, listas)
  static const double iconSizeM = 24.0;

  /// 32px - Iconos grandes (destacados)
  static const double iconSizeL = 32.0;

  /// 48px - Iconos extra grandes (empty states)
  static const double iconSizeXl = 48.0;

  /// 64px - Iconos hero (splash, onboarding)
  static const double iconSizeXxl = 64.0;

  // ============================================
  // === ELEVACIONES ===
  // ============================================

  /// Sin elevacion
  static const double elevation0 = 0.0;

  /// Elevacion baja (cards sutiles)
  static const double elevationS = 2.0;

  /// Elevacion media (cards, botones)
  static const double elevationM = 4.0;

  /// Elevacion alta (modales, drawers)
  static const double elevationL = 8.0;

  /// Elevacion maxima (dialogos)
  static const double elevationXl = 16.0;

  // ============================================
  // === OPACIDADES ===
  // ============================================

  /// Opacidad deshabilitado
  static const double opacityDisabled = 0.38;

  /// Opacidad hover
  static const double opacityHover = 0.08;

  /// Opacidad focus
  static const double opacityFocus = 0.12;

  /// Opacidad pressed
  static const double opacityPressed = 0.16;

  /// Opacidad overlay
  static const double opacityOverlay = 0.5;
}
