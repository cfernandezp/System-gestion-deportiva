import 'package:equatable/equatable.dart';

import '../../../fechas/data/models/color_equipo.dart';

/// Modelo de equipo con su score para el marcador en vivo
/// E004-HU-004: Ver Score en Vivo
/// CA-001: Marcador visible (Equipo1 [goles] - [goles] Equipo2)
/// CA-002: Colores de equipo (naranja, verde, azul)
class EquipoScoreModel extends Equatable {
  /// Color del equipo
  final ColorEquipo color;

  /// Cantidad de goles anotados
  final int goles;

  /// Indica si este equipo es el local
  final bool esLocal;

  const EquipoScoreModel({
    required this.color,
    required this.goles,
    required this.esLocal,
  });

  /// Factory desde JSON del backend
  /// Mapea snake_case a camelCase
  factory EquipoScoreModel.fromJson(Map<String, dynamic> json) {
    return EquipoScoreModel(
      color: ColorEquipo.fromString(json['color'] as String?) ??
          ColorEquipo.naranja,
      goles: json['goles'] as int? ?? 0,
      esLocal: json['es_local'] as bool? ?? false,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'color': color.toBackend(),
      'goles': goles,
      'es_local': esLocal,
    };
  }

  @override
  List<Object?> get props => [color, goles, esLocal];
}
