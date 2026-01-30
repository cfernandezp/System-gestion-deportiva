import 'package:equatable/equatable.dart';

import 'color_equipo.dart';

/// Modelo de respuesta del RPC asignar_equipo
/// E003-HU-005: Asignar Equipos
/// CA-004, CA-005: Asignacion manual de jugador a equipo
/// CA-008: Modificar antes de iniciar
///
/// JSON Response Success:
/// {
///   "success": true,
///   "data": {
///     "asignacion_id": "uuid",
///     "usuario_nombre": "Nombre",
///     "equipo": "naranja",
///     "es_actualizacion": false
///   },
///   "message": "Jugador asignado al equipo naranja"
/// }
class AsignarEquipoResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos de la asignacion (null si error)
  final AsignarEquipoDataModel? data;

  /// Mensaje del servidor
  final String message;

  const AsignarEquipoResponseModel({
    required this.success,
    this.data,
    this.message = '',
  });

  /// Crea instancia desde JSON del backend
  factory AsignarEquipoResponseModel.fromJson(Map<String, dynamic> json) {
    return AsignarEquipoResponseModel(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? AsignarEquipoDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}

/// Modelo de datos de asignacion individual
class AsignarEquipoDataModel extends Equatable {
  /// ID de la asignacion creada/actualizada
  final String asignacionId;

  /// Nombre del usuario asignado
  final String usuarioNombre;

  /// Equipo asignado
  final ColorEquipo equipo;

  /// CA-008: Indica si fue actualizacion (true) o nueva asignacion (false)
  final bool esActualizacion;

  const AsignarEquipoDataModel({
    required this.asignacionId,
    required this.usuarioNombre,
    required this.equipo,
    required this.esActualizacion,
  });

  /// Crea instancia desde JSON del backend
  factory AsignarEquipoDataModel.fromJson(Map<String, dynamic> json) {
    return AsignarEquipoDataModel(
      asignacionId: json['asignacion_id'] ?? '',
      usuarioNombre: json['usuario_nombre'] ?? '',
      equipo: ColorEquipo.fromString(json['equipo']) ?? ColorEquipo.naranja,
      esActualizacion: json['es_actualizacion'] ?? false,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'asignacion_id': asignacionId,
      'usuario_nombre': usuarioNombre,
      'equipo': equipo.toBackend(),
      'es_actualizacion': esActualizacion,
    };
  }

  @override
  List<Object?> get props => [asignacionId, usuarioNombre, equipo, esActualizacion];
}
