import 'package:equatable/equatable.dart';

import 'color_equipo.dart';
import 'jugador_asignacion_model.dart';
import 'equipo_resumen_model.dart';
import 'asignaciones_resumen_model.dart';
import 'fecha_asignacion_info_model.dart';

/// Modelo de respuesta del RPC obtener_asignaciones
/// E003-HU-005: Asignar Equipos
/// CA-001: Lista de inscritos y equipos disponibles
/// CA-002: Equipos segun formato (2 o 3)
/// CA-003: Colores de equipos distintivos
///
/// JSON Response:
/// {
///   "success": true,
///   "data": {
///     "fecha": {...},
///     "colores_disponibles": ["naranja", "verde"],
///     "jugadores": [...],
///     "equipos": [...],
///     "resumen": {...}
///   }
/// }
class ObtenerAsignacionesResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos de asignaciones (null si error)
  final ObtenerAsignacionesDataModel? data;

  /// Mensaje del servidor
  final String message;

  const ObtenerAsignacionesResponseModel({
    required this.success,
    this.data,
    this.message = '',
  });

  /// Crea instancia desde JSON del backend
  factory ObtenerAsignacionesResponseModel.fromJson(Map<String, dynamic> json) {
    return ObtenerAsignacionesResponseModel(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? ObtenerAsignacionesDataModel.fromJson(
              json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}

/// Modelo de datos de asignaciones
class ObtenerAsignacionesDataModel extends Equatable {
  /// Informacion de la fecha
  final FechaAsignacionInfoModel fecha;

  /// CA-003: Colores disponibles para asignar segun num_equipos
  /// RN-004: Para 2 equipos: naranja, verde. Para 3: +azul
  final List<ColorEquipo> coloresDisponibles;

  /// CA-001: Lista de todos los jugadores inscritos con su equipo
  final List<JugadorAsignacionModel> jugadores;

  /// CA-001: Resumen de equipos con jugadores asignados
  final List<EquipoResumenModel> equipos;

  /// RN-005: Resumen de progreso de asignacion
  final AsignacionesResumenModel resumen;

  const ObtenerAsignacionesDataModel({
    required this.fecha,
    required this.coloresDisponibles,
    required this.jugadores,
    required this.equipos,
    required this.resumen,
  });

  /// Crea instancia desde JSON del backend
  factory ObtenerAsignacionesDataModel.fromJson(Map<String, dynamic> json) {
    // Parsear colores disponibles
    final coloresList = json['colores_disponibles'] as List<dynamic>? ?? [];
    final colores = coloresList
        .map((c) => ColorEquipo.fromString(c as String))
        .whereType<ColorEquipo>()
        .toList();

    // Parsear jugadores
    final jugadoresList = json['jugadores'] as List<dynamic>? ?? [];
    final jugadores = jugadoresList
        .map((j) => JugadorAsignacionModel.fromJson(j as Map<String, dynamic>))
        .toList();

    // Parsear equipos
    final equiposList = json['equipos'] as List<dynamic>? ?? [];
    final equipos = equiposList
        .map((e) => EquipoResumenModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ObtenerAsignacionesDataModel(
      fecha: FechaAsignacionInfoModel.fromJson(
          json['fecha'] as Map<String, dynamic>? ?? {}),
      coloresDisponibles: colores,
      jugadores: jugadores,
      equipos: equipos,
      resumen: AsignacionesResumenModel.fromJson(
          json['resumen'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Obtiene jugadores sin equipo asignado
  List<JugadorAsignacionModel> get jugadoresSinAsignar {
    return jugadores.where((j) => !j.asignado).toList();
  }

  /// Obtiene jugadores de un equipo especifico
  List<JugadorAsignacionModel> jugadoresDelEquipo(ColorEquipo equipo) {
    return jugadores.where((j) => j.equipo == equipo).toList();
  }

  @override
  List<Object?> get props => [
        fecha,
        coloresDisponibles,
        jugadores,
        equipos,
        resumen,
      ];
}
