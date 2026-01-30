import 'package:equatable/equatable.dart';

/// Modelo de resumen de asignaciones
/// E003-HU-005: Asignar Equipos
/// RN-005: Asignacion Completa Requerida
///
/// JSON esperado del RPC obtener_asignaciones:
/// {
///   "total_inscritos": 10,
///   "total_asignados": 5,
///   "sin_asignar": 5,
///   "asignacion_completa": false
/// }
class AsignacionesResumenModel extends Equatable {
  /// Total de jugadores inscritos a la fecha
  final int totalInscritos;

  /// Total de jugadores con equipo asignado
  final int totalAsignados;

  /// Cantidad de jugadores sin equipo
  final int sinAsignar;

  /// RN-005: Indica si todos tienen equipo asignado
  final bool asignacionCompleta;

  const AsignacionesResumenModel({
    required this.totalInscritos,
    required this.totalAsignados,
    required this.sinAsignar,
    required this.asignacionCompleta,
  });

  /// Crea instancia desde JSON del backend
  factory AsignacionesResumenModel.fromJson(Map<String, dynamic> json) {
    return AsignacionesResumenModel(
      totalInscritos: json['total_inscritos'] ?? 0,
      totalAsignados: json['total_asignados'] ?? 0,
      sinAsignar: json['sin_asignar'] ?? 0,
      asignacionCompleta: json['asignacion_completa'] ?? false,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'total_inscritos': totalInscritos,
      'total_asignados': totalAsignados,
      'sin_asignar': sinAsignar,
      'asignacion_completa': asignacionCompleta,
    };
  }

  /// Porcentaje de progreso de asignacion
  double get porcentajeAsignado {
    if (totalInscritos == 0) return 0;
    return totalAsignados / totalInscritos;
  }

  @override
  List<Object?> get props => [
        totalInscritos,
        totalAsignados,
        sinAsignar,
        asignacionCompleta,
      ];
}
