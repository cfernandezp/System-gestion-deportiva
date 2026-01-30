import 'package:equatable/equatable.dart';

import 'color_equipo.dart';

/// Modelo de equipo confirmado
/// E003-HU-005: Asignar Equipos
/// CA-007: Confirmar asignacion
///
/// JSON esperado del RPC confirmar_equipos:
/// {
///   "equipo": "naranja",
///   "cantidad": 6
/// }
class EquipoConfirmadoModel extends Equatable {
  /// Color del equipo
  final ColorEquipo equipo;

  /// Cantidad de jugadores en el equipo
  final int cantidad;

  const EquipoConfirmadoModel({
    required this.equipo,
    required this.cantidad,
  });

  /// Crea instancia desde JSON del backend
  factory EquipoConfirmadoModel.fromJson(Map<String, dynamic> json) {
    return EquipoConfirmadoModel(
      equipo: ColorEquipo.fromString(json['equipo']) ?? ColorEquipo.naranja,
      cantidad: json['cantidad'] ?? 0,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'equipo': equipo.toBackend(),
      'cantidad': cantidad,
    };
  }

  @override
  List<Object?> get props => [equipo, cantidad];
}
