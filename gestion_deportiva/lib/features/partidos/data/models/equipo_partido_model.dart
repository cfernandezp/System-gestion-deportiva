import 'package:equatable/equatable.dart';

import 'jugador_partido_model.dart';

/// Modelo de Equipo dentro de un partido
/// E004-HU-001: Iniciar Partido - CA-001
class EquipoPartidoModel extends Equatable {
  final String color;
  final int jugadoresCount;
  final List<JugadorPartidoModel> jugadores;

  const EquipoPartidoModel({
    required this.color,
    required this.jugadoresCount,
    required this.jugadores,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory EquipoPartidoModel.fromJson(Map<String, dynamic> json) {
    final jugadoresList = json['jugadores'] as List<dynamic>? ?? [];
    return EquipoPartidoModel(
      color: json['color'] ?? '',
      jugadoresCount: json['jugadores_count'] ?? 0,
      jugadores: jugadoresList
          .map((j) => JugadorPartidoModel.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'color': color,
      'jugadores_count': jugadoresCount,
      'jugadores': jugadores.map((j) => j.toJson()).toList(),
    };
  }

  /// Nombre del equipo para mostrar en UI (capitalizado)
  String get displayName => color.isNotEmpty
      ? '${color[0].toUpperCase()}${color.substring(1)}'
      : '';

  @override
  List<Object?> get props => [color, jugadoresCount, jugadores];
}
