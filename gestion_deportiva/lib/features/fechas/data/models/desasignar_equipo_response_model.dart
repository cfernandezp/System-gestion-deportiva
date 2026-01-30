import 'package:equatable/equatable.dart';

/// Modelo de respuesta del RPC desasignar_equipo
/// E003-HU-005: Asignar Equipos
/// Permite devolver un jugador a "Sin Asignar"
///
/// JSON Response Success:
/// {
///   "success": true,
///   "data": {
///     "fecha_id": "uuid",
///     "usuario_id": "uuid",
///     "usuario_nombre": "Nombre",
///     "equipo_anterior": "naranja"
///   },
///   "message": "Jugador removido del equipo naranja"
/// }
class DesasignarEquipoResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos de la desasignacion (null si error)
  final DesasignarEquipoDataModel? data;

  /// Mensaje del servidor
  final String message;

  const DesasignarEquipoResponseModel({
    required this.success,
    this.data,
    this.message = '',
  });

  /// Crea instancia desde JSON del backend
  factory DesasignarEquipoResponseModel.fromJson(Map<String, dynamic> json) {
    return DesasignarEquipoResponseModel(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? DesasignarEquipoDataModel.fromJson(
              json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}

/// Modelo de datos de desasignacion
class DesasignarEquipoDataModel extends Equatable {
  /// ID de la fecha
  final String fechaId;

  /// ID del usuario desasignado
  final String usuarioId;

  /// Nombre del usuario desasignado
  final String usuarioNombre;

  /// Equipo del que fue removido
  final String equipoAnterior;

  const DesasignarEquipoDataModel({
    required this.fechaId,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.equipoAnterior,
  });

  /// Crea instancia desde JSON del backend
  factory DesasignarEquipoDataModel.fromJson(Map<String, dynamic> json) {
    return DesasignarEquipoDataModel(
      fechaId: json['fecha_id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      usuarioNombre: json['usuario_nombre'] ?? '',
      equipoAnterior: json['equipo_anterior'] ?? '',
    );
  }

  @override
  List<Object?> get props => [fechaId, usuarioId, usuarioNombre, equipoAnterior];
}
