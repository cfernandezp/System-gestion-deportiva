import 'package:equatable/equatable.dart';

import 'color_equipo.dart';
import 'jugador_asignacion_model.dart';

/// Modelo de resumen de un equipo con sus jugadores
/// E003-HU-005: Asignar Equipos
/// CA-001: Equipos disponibles a la derecha (con colores)
///
/// JSON esperado del RPC obtener_asignaciones (en array equipos):
/// {
///   "equipo": "naranja",
///   "cantidad": 5,
///   "jugadores": [...]
/// }
class EquipoResumenModel extends Equatable {
  /// Color del equipo
  final ColorEquipo equipo;

  /// Cantidad de jugadores asignados
  final int cantidad;

  /// Lista de jugadores asignados al equipo
  final List<JugadorAsignacionModel> jugadores;

  const EquipoResumenModel({
    required this.equipo,
    required this.cantidad,
    required this.jugadores,
  });

  /// Crea instancia desde JSON del backend
  factory EquipoResumenModel.fromJson(Map<String, dynamic> json) {
    final colorStr = json['equipo'] as String?;
    final jugadoresList = json['jugadores'] as List<dynamic>? ?? [];

    return EquipoResumenModel(
      equipo: ColorEquipo.fromString(colorStr) ?? ColorEquipo.naranja,
      cantidad: json['cantidad'] ?? 0,
      jugadores: jugadoresList
          .map((j) => JugadorAsignacionModel.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'equipo': equipo.toBackend(),
      'cantidad': cantidad,
      'jugadores': jugadores.map((j) => j.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [equipo, cantidad, jugadores];
}
