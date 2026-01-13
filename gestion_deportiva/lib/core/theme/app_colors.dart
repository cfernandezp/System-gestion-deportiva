import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Clase helper para acceder a colores segun el theme actual
/// Proporciona metodos estaticos para obtener colores de forma segura
class AppColors {
  AppColors._();

  // ============================================
  // === COLORES PRINCIPALES DEL THEME ===
  // ============================================

  /// Color primario del theme actual
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Color sobre primario (texto/iconos sobre primary)
  static Color onPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;

  /// Contenedor primario (version suave del primary)
  static Color primaryContainer(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;

  /// Color sobre contenedor primario
  static Color onPrimaryContainer(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimaryContainer;

  /// Color secundario del theme actual
  static Color secondary(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  /// Color sobre secundario
  static Color onSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSecondary;

  /// Contenedor secundario
  static Color secondaryContainer(BuildContext context) =>
      Theme.of(context).colorScheme.secondaryContainer;

  /// Color sobre contenedor secundario
  static Color onSecondaryContainer(BuildContext context) =>
      Theme.of(context).colorScheme.onSecondaryContainer;

  /// Color terciario (accent)
  static Color tertiary(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;

  /// Color sobre terciario
  static Color onTertiary(BuildContext context) =>
      Theme.of(context).colorScheme.onTertiary;

  // ============================================
  // === COLORES DE SUPERFICIE ===
  // ============================================

  /// Color de fondo principal
  static Color background(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Color de superficie (cards, sheets)
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Color de superficie variante
  static Color surfaceVariant(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  /// Color sobre fondo
  static Color onBackground(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Color sobre superficie
  static Color onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Color sobre superficie variante (texto secundario)
  static Color onSurfaceVariant(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  // ============================================
  // === COLORES DE BORDE ===
  // ============================================

  /// Color de borde principal
  static Color outline(BuildContext context) =>
      Theme.of(context).colorScheme.outline;

  /// Color de borde variante (mas sutil)
  static Color outlineVariant(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  // ============================================
  // === COLORES SEMANTICOS ===
  // ============================================

  /// Color de error
  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  /// Color sobre error
  static Color onError(BuildContext context) =>
      Theme.of(context).colorScheme.onError;

  /// Contenedor de error
  static Color errorContainer(BuildContext context) =>
      Theme.of(context).colorScheme.errorContainer;

  /// Color sobre contenedor de error
  static Color onErrorContainer(BuildContext context) =>
      Theme.of(context).colorScheme.onErrorContainer;

  // ============================================
  // === COLORES SEMANTICOS DEPORTIVOS ===
  // ============================================

  /// Verde - Victoria, exito, activo
  static const Color victoria = Color(0xFF22C55E);

  /// Rojo - Derrota, error, inactivo
  static const Color derrota = Color(0xFFEF4444);

  /// Gris - Empate, neutral
  static const Color empate = Color(0xFF64748B);

  /// Naranja - En curso, pendiente, advertencia
  static const Color enCurso = Color(0xFFF59E0B);

  /// Gris oscuro - Cancelado, no disponible
  static const Color cancelado = Color(0xFF6B7280);

  /// Azul - Programado, futuro
  static const Color programado = Color(0xFF3B82F6);

  /// Morado - Destacado, premium
  static const Color destacado = Color(0xFF8B5CF6);

  // ============================================
  // === COLORES DE POSICION (Rankings) ===
  // ============================================

  /// Oro - Primer lugar
  static const Color oro = Color(0xFFFFD700);

  /// Plata - Segundo lugar
  static const Color plata = Color(0xFFC0C0C0);

  /// Bronce - Tercer lugar
  static const Color bronce = Color(0xFFCD7F32);

  // ============================================
  // === COLORES DE EQUIPO (Defaults) ===
  // ============================================

  /// Equipo local (default)
  static const Color equipoLocal = Color(0xFF10B981);

  /// Equipo visitante (default)
  static const Color equipoVisitante = Color(0xFF1E40AF);

  // ============================================
  // === HELPERS DE ESTADO ===
  // ============================================

  /// Retorna el color segun el estado del partido
  static Color estadoPartido(String estado) {
    switch (estado.toLowerCase()) {
      case 'en_curso':
      case 'encurso':
      case 'en curso':
        return enCurso;
      case 'finalizado':
      case 'terminado':
        return victoria;
      case 'cancelado':
        return cancelado;
      case 'programado':
      case 'pendiente':
        return programado;
      default:
        return empate;
    }
  }

  /// Retorna el color segun el resultado
  static Color resultado(String resultado) {
    switch (resultado.toLowerCase()) {
      case 'victoria':
      case 'ganado':
      case 'win':
        return victoria;
      case 'derrota':
      case 'perdido':
      case 'loss':
        return derrota;
      case 'empate':
      case 'draw':
        return empate;
      default:
        return empate;
    }
  }

  /// Retorna el color segun la posicion en ranking
  static Color posicionRanking(int posicion) {
    switch (posicion) {
      case 1:
        return oro;
      case 2:
        return plata;
      case 3:
        return bronce;
      default:
        return empate;
    }
  }

  /// Retorna el color segun si esta activo/inactivo
  static Color estadoActivo(bool activo) {
    return activo ? victoria : cancelado;
  }

  // ============================================
  // === HELPERS DE CONTRASTE ===
  // ============================================

  /// Determina si el texto debe ser claro u oscuro sobre un color
  static Color textoSobre(Color color) {
    // Calcula luminancia relativa
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? DesignTokens.lightOnSurface : Colors.white;
  }

  /// Retorna una version con alpha del color
  static Color withAlpha(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // ============================================
  // === SOMBRAS SEGUN THEME ===
  // ============================================

  /// Retorna sombras apropiadas segun el theme
  static List<BoxShadow> shadow(BuildContext context, {String size = 'md'}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (size) {
      case 'sm':
        return isDark ? DesignTokens.shadowSmDark : DesignTokens.shadowSm;
      case 'md':
        return isDark ? DesignTokens.shadowMdDark : DesignTokens.shadowMd;
      case 'lg':
        return isDark ? DesignTokens.shadowLgDark : DesignTokens.shadowLg;
      default:
        return isDark ? DesignTokens.shadowMdDark : DesignTokens.shadowMd;
    }
  }

  /// Verifica si el tema actual es oscuro
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
