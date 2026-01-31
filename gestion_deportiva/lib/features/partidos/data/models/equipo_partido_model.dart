import 'package:equatable/equatable.dart';

import '../../../fechas/data/models/color_equipo.dart';
import 'jugador_partido_model.dart';

/// Modelo de equipo en un partido
/// E004-HU-001: Iniciar Partido
/// CA-001: Seleccionar equipos con color y jugadores
class EquipoPartidoModel extends Equatable {
  final ColorEquipo color;
  final int jugadoresCount;
  final List<JugadorPartidoModel> jugadores;

  const EquipoPartidoModel({
    required this.color,
    required this.jugadoresCount,
    required this.jugadores,
  });

  /// Factory desde JSON del backend
  /// Mapea snake_case a camelCase
  factory EquipoPartidoModel.fromJson(Map<String, dynamic> json) {
    final jugadoresJson = json['jugadores'] as List<dynamic>? ?? [];
    return EquipoPartidoModel(
      color: ColorEquipo.fromString(json['color'] as String?) ??
          ColorEquipo.naranja,
      jugadoresCount: json['jugadores_count'] as int? ?? 0,
      jugadores: jugadoresJson
          .map((j) => JugadorPartidoModel.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'color': color.toBackend(),
      'jugadores_count': jugadoresCount,
      'jugadores': jugadores.map((j) => j.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [color, jugadoresCount, jugadores];
}
