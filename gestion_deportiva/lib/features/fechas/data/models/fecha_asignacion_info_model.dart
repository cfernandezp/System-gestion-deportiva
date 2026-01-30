import 'package:equatable/equatable.dart';

/// Modelo de informacion de la fecha para asignaciones
/// E003-HU-005: Asignar Equipos
/// RN-002: Estado Valido para Asignar
/// RN-003: Cantidad de Equipos por Duracion
///
/// JSON esperado del RPC obtener_asignaciones:
/// {
///   "id": "uuid",
///   "num_equipos": 2,
///   "estado": "cerrada",
///   "puede_asignar": true
/// }
class FechaAsignacionInfoModel extends Equatable {
  /// ID de la fecha
  final String id;

  /// RN-003: Numero de equipos segun duracion (2 o 3)
  final int numEquipos;

  /// Estado actual de la fecha
  final String estado;

  /// RN-002: Indica si se pueden asignar equipos
  /// Solo true cuando estado = 'cerrada'
  final bool puedeAsignar;

  const FechaAsignacionInfoModel({
    required this.id,
    required this.numEquipos,
    required this.estado,
    required this.puedeAsignar,
  });

  /// Crea instancia desde JSON del backend
  factory FechaAsignacionInfoModel.fromJson(Map<String, dynamic> json) {
    return FechaAsignacionInfoModel(
      id: json['id'] ?? '',
      numEquipos: json['num_equipos'] ?? 2,
      estado: json['estado'] ?? '',
      puedeAsignar: json['puede_asignar'] ?? false,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'num_equipos': numEquipos,
      'estado': estado,
      'puede_asignar': puedeAsignar,
    };
  }

  /// Verifica si la fecha esta cerrada (permitiendo asignaciones)
  bool get estaCerrada => estado == 'cerrada';

  /// Descripcion del formato de juego
  String get formatoJuego => '$numEquipos equipos';

  @override
  List<Object?> get props => [id, numEquipos, estado, puedeAsignar];
}
