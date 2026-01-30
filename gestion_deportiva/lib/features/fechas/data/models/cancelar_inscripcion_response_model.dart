import 'package:equatable/equatable.dart';

/// Modelo de datos de cancelacion de inscripcion
/// E003-HU-007: Cancelar Inscripcion
///
/// Criterios de Aceptacion:
/// - CA-003: Cancelacion exitosa con deuda anulada
/// - CA-004: Re-inscripcion permitida
///
/// Reglas de Negocio:
/// - RN-003: Deuda se anula si fecha esta abierta
/// - RN-004: Asignacion de equipo se elimina
/// - RN-006: Soft delete con auditoria
class CancelarInscripcionDataModel extends Equatable {
  /// ID de la inscripcion cancelada
  final String inscripcionId;

  /// ID de la fecha
  final String fechaId;

  /// Fecha formateada (DD/MM/YYYY HH24:MI)
  final String fechaFormato;

  /// Lugar de la pichanga
  final String lugar;

  /// Estado de la inscripcion ('cancelado')
  final String estadoInscripcion;

  /// RN-003: Indica si la deuda fue anulada
  final bool deudaAnulada;

  /// RN-004: Indica si se elimino asignacion de equipo
  final bool asignacionEliminada;

  /// CA-004: Indica si el usuario puede volver a inscribirse
  final bool puedeReinscribirse;

  /// RN-006: Timestamp de cancelacion (UTC)
  final DateTime canceladoAt;

  /// RN-006: Timestamp de cancelacion formateado (DD/MM/YYYY HH24:MI)
  final String canceladoAtFormato;

  const CancelarInscripcionDataModel({
    required this.inscripcionId,
    required this.fechaId,
    required this.fechaFormato,
    required this.lugar,
    required this.estadoInscripcion,
    required this.deudaAnulada,
    required this.asignacionEliminada,
    required this.puedeReinscribirse,
    required this.canceladoAt,
    required this.canceladoAtFormato,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  ///
  /// Response format del backend:
  /// {
  ///   "inscripcion_id": "uuid",
  ///   "fecha_id": "uuid",
  ///   "fecha_formato": "DD/MM/YYYY HH24:MI",
  ///   "lugar": "string",
  ///   "estado_inscripcion": "cancelado",
  ///   "deuda_anulada": true,
  ///   "asignacion_eliminada": false,
  ///   "puede_reinscribirse": true,
  ///   "cancelado_at": "timestamp",
  ///   "cancelado_at_formato": "DD/MM/YYYY HH24:MI"
  /// }
  factory CancelarInscripcionDataModel.fromJson(Map<String, dynamic> json) {
    return CancelarInscripcionDataModel(
      inscripcionId: json['inscripcion_id'] ?? '',
      fechaId: json['fecha_id'] ?? '',
      fechaFormato: json['fecha_formato'] ?? '',
      lugar: json['lugar'] ?? '',
      estadoInscripcion: json['estado_inscripcion'] ?? 'cancelado',
      deudaAnulada: json['deuda_anulada'] ?? false,
      asignacionEliminada: json['asignacion_eliminada'] ?? false,
      puedeReinscribirse: json['puede_reinscribirse'] ?? true,
      canceladoAt: json['cancelado_at'] != null
          ? DateTime.parse(json['cancelado_at']).toLocal()
          : DateTime.now(),
      canceladoAtFormato: json['cancelado_at_formato'] ?? '',
    );
  }

  /// Verifica si la cancelacion fue exitosa
  bool get cancelacionExitosa => estadoInscripcion == 'cancelado';

  @override
  List<Object?> get props => [
        inscripcionId,
        fechaId,
        fechaFormato,
        lugar,
        estadoInscripcion,
        deudaAnulada,
        asignacionEliminada,
        puedeReinscribirse,
        canceladoAt,
        canceladoAtFormato,
      ];
}

/// Wrapper de respuesta completa del RPC cancelar_inscripcion
/// Sigue el formato estandar de response: {success, data, message}
/// E003-HU-007: Cancelar Inscripcion (jugador cancela su propia inscripcion)
class CancelarInscripcionRpcResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos de la respuesta (null si error)
  final CancelarInscripcionDataModel? data;

  /// Mensaje descriptivo del servidor
  final String message;

  const CancelarInscripcionRpcResponseModel({
    required this.success,
    this.data,
    required this.message,
  });

  /// Crea instancia desde JSON completo del backend
  factory CancelarInscripcionRpcResponseModel.fromJson(
      Map<String, dynamic> json) {
    final dataJson = json['data'] as Map<String, dynamic>?;

    return CancelarInscripcionRpcResponseModel(
      success: json['success'] ?? false,
      data: dataJson != null
          ? CancelarInscripcionDataModel.fromJson(dataJson)
          : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}

/// Modelo de jugador afectado por cancelacion admin
/// E003-HU-007: CA-006 Cancelacion por admin
class JugadorAfectadoModel extends Equatable {
  /// ID del jugador
  final String id;

  /// Nombre del jugador
  final String nombre;

  const JugadorAfectadoModel({
    required this.id,
    required this.nombre,
  });

  /// Crea instancia desde JSON del backend
  factory JugadorAfectadoModel.fromJson(Map<String, dynamic> json) {
    return JugadorAfectadoModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, nombre];
}

/// Modelo de admin que realizo la cancelacion
/// E003-HU-007: RN-006 Registro de cancelacion
class AdminCanceladorModel extends Equatable {
  /// ID del admin
  final String id;

  /// Nombre del admin
  final String nombre;

  const AdminCanceladorModel({
    required this.id,
    required this.nombre,
  });

  /// Crea instancia desde JSON del backend
  factory AdminCanceladorModel.fromJson(Map<String, dynamic> json) {
    return AdminCanceladorModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, nombre];
}

/// Modelo de datos de cancelacion de inscripcion por admin
/// E003-HU-007: CA-006 Cancelacion por admin
///
/// Response format del backend para cancelar_inscripcion_admin:
/// {
///   "inscripcion_id": "uuid",
///   "fecha_id": "uuid",
///   "fecha_formato": "DD/MM/YYYY HH24:MI",
///   "lugar": "string",
///   "jugador": {"id": "uuid", "nombre": "string"},
///   "estado_inscripcion": "cancelado",
///   "deuda_anulada": true,
///   "asignacion_eliminada": false,
///   "cancelado_por": {"id": "uuid", "nombre": "string"},
///   "cancelado_at": "timestamp",
///   "cancelado_at_formato": "DD/MM/YYYY HH24:MI"
/// }
class CancelarInscripcionAdminDataModel extends Equatable {
  /// ID de la inscripcion cancelada
  final String inscripcionId;

  /// ID de la fecha
  final String fechaId;

  /// Fecha formateada (DD/MM/YYYY HH24:MI)
  final String fechaFormato;

  /// Lugar de la pichanga
  final String lugar;

  /// Datos del jugador afectado
  final JugadorAfectadoModel jugador;

  /// Estado de la inscripcion ('cancelado')
  final String estadoInscripcion;

  /// RN-003: Indica si la deuda fue anulada
  final bool deudaAnulada;

  /// RN-004: Indica si se elimino asignacion de equipo
  final bool asignacionEliminada;

  /// RN-006: Admin que realizo la cancelacion
  final AdminCanceladorModel canceladoPor;

  /// RN-006: Timestamp de cancelacion (UTC)
  final DateTime canceladoAt;

  /// RN-006: Timestamp de cancelacion formateado (DD/MM/YYYY HH24:MI)
  final String canceladoAtFormato;

  const CancelarInscripcionAdminDataModel({
    required this.inscripcionId,
    required this.fechaId,
    required this.fechaFormato,
    required this.lugar,
    required this.jugador,
    required this.estadoInscripcion,
    required this.deudaAnulada,
    required this.asignacionEliminada,
    required this.canceladoPor,
    required this.canceladoAt,
    required this.canceladoAtFormato,
  });

  /// Crea instancia desde JSON del backend
  factory CancelarInscripcionAdminDataModel.fromJson(Map<String, dynamic> json) {
    return CancelarInscripcionAdminDataModel(
      inscripcionId: json['inscripcion_id'] ?? '',
      fechaId: json['fecha_id'] ?? '',
      fechaFormato: json['fecha_formato'] ?? '',
      lugar: json['lugar'] ?? '',
      jugador: JugadorAfectadoModel.fromJson(
          json['jugador'] as Map<String, dynamic>? ?? {}),
      estadoInscripcion: json['estado_inscripcion'] ?? 'cancelado',
      deudaAnulada: json['deuda_anulada'] ?? false,
      asignacionEliminada: json['asignacion_eliminada'] ?? false,
      canceladoPor: AdminCanceladorModel.fromJson(
          json['cancelado_por'] as Map<String, dynamic>? ?? {}),
      canceladoAt: json['cancelado_at'] != null
          ? DateTime.parse(json['cancelado_at']).toLocal()
          : DateTime.now(),
      canceladoAtFormato: json['cancelado_at_formato'] ?? '',
    );
  }

  /// Verifica si la cancelacion fue exitosa
  bool get cancelacionExitosa => estadoInscripcion == 'cancelado';

  @override
  List<Object?> get props => [
        inscripcionId,
        fechaId,
        fechaFormato,
        lugar,
        jugador,
        estadoInscripcion,
        deudaAnulada,
        asignacionEliminada,
        canceladoPor,
        canceladoAt,
        canceladoAtFormato,
      ];
}

/// Wrapper de respuesta completa del RPC cancelar_inscripcion_admin
/// Sigue el formato estandar de response: {success, data, message}
/// E003-HU-007: CA-006 Cancelacion por admin
class CancelarInscripcionAdminRpcResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos de la respuesta (null si error)
  final CancelarInscripcionAdminDataModel? data;

  /// Mensaje descriptivo del servidor
  final String message;

  const CancelarInscripcionAdminRpcResponseModel({
    required this.success,
    this.data,
    required this.message,
  });

  /// Crea instancia desde JSON completo del backend
  factory CancelarInscripcionAdminRpcResponseModel.fromJson(
      Map<String, dynamic> json) {
    final dataJson = json['data'] as Map<String, dynamic>?;

    return CancelarInscripcionAdminRpcResponseModel(
      success: json['success'] ?? false,
      data: dataJson != null
          ? CancelarInscripcionAdminDataModel.fromJson(dataJson)
          : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}
