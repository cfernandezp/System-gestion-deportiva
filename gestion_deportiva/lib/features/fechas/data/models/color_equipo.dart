import 'package:flutter/material.dart';

/// Enum de colores de equipo disponibles
/// E003-HU-005: Asignar Equipos
/// RN-004: Colores de Equipos Predefinidos
/// Catalogo: naranja, verde, azul, rojo, amarillo, blanco
enum ColorEquipo {
  naranja,
  verde,
  azul,
  rojo,
  amarillo,
  blanco;

  /// Convierte string del backend a enum
  /// Si el valor no coincide, retorna null
  static ColorEquipo? fromString(String? value) {
    if (value == null) return null;
    return ColorEquipo.values.cast<ColorEquipo?>().firstWhere(
          (e) => e?.name == value.toLowerCase(),
          orElse: () => null,
        );
  }

  /// Convierte enum a string para enviar al backend
  String toBackend() => name;

  /// Color de Flutter para la UI
  /// CA-003: Colores distintivos para cada equipo
  Color get color {
    switch (this) {
      case ColorEquipo.naranja:
        return const Color(0xFFFF9800);
      case ColorEquipo.verde:
        return const Color(0xFF4CAF50);
      case ColorEquipo.azul:
        return const Color(0xFF2196F3);
      case ColorEquipo.rojo:
        return const Color(0xFFF44336);
      case ColorEquipo.amarillo:
        return const Color(0xFFFFEB3B);
      case ColorEquipo.blanco:
        return const Color(0xFFFFFFFF);
    }
  }

  /// Color de texto contrastante para legibilidad
  Color get textColor {
    switch (this) {
      case ColorEquipo.naranja:
      case ColorEquipo.rojo:
      case ColorEquipo.verde:
      case ColorEquipo.azul:
        return Colors.white;
      case ColorEquipo.amarillo:
      case ColorEquipo.blanco:
        return Colors.black87;
    }
  }

  /// Color de borde para el chip/badge
  Color get borderColor {
    switch (this) {
      case ColorEquipo.blanco:
        return Colors.grey.shade400;
      default:
        return color;
    }
  }

  /// Nombre formateado para mostrar en UI
  /// Primera letra mayuscula
  String get displayName {
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}
