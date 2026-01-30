import 'package:equatable/equatable.dart';

/// Modelo de respuesta para reabrir_inscripciones RPC
/// E003-HU-004: Cerrar Inscripciones (CA-006: Reabrir)
///
/// Criterios de Aceptacion:
/// - CA-006: Reabrir inscripciones para agregar mas jugadores
///
/// Reglas de Negocio:
/// - RN-001: Solo admin aprobado puede reabrir
/// - RN-005: Solo fechas con estado 'cerrada' (no en_juego ni finalizada)
/// - RN-006: Inscripciones y deudas se mantienen intactas
class ReabrirInscripcionesResponseModel extends Equatable {
  /// ID de la fecha reabierta
  final String fechaId;

  /// Fecha formateada (DD/MM/YYYY HH24:MI)
  final String fechaFormato;

  /// Lugar de la pichanga
  final String lugar;

  /// Estado anterior de la fecha ('cerrada')
  final String estadoAnterior;

  /// Estado nuevo de la fecha ('abierta')
  final String estadoNuevo;

  /// Total de jugadores inscritos (se mantienen)
  final int totalInscritos;

  /// RN-006: Indica que las inscripciones se mantuvieron
  final bool inscripcionesMantenidas;

  /// RN-006: Indica que las deudas se mantuvieron
  final bool deudasMantenidas;

  /// RN-005: Cantidad de asignaciones de equipo eliminadas
  final int asignacionesEliminadas;

  /// ID del admin que reabrio las inscripciones
  final String reabiertoPor;

  /// Nombre del admin que reabrio
  final String reabiertoPorNombre;

  /// Timestamp de reapertura (UTC)
  final DateTime reabiertoAt;

  /// Timestamp de reapertura formateado (DD/MM/YYYY HH24:MI)
  final String reabiertoAtFormato;

  const ReabrirInscripcionesResponseModel({
    required this.fechaId,
    required this.fechaFormato,
    required this.lugar,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.totalInscritos,
    required this.inscripcionesMantenidas,
    required this.deudasMantenidas,
    required this.asignacionesEliminadas,
    required this.reabiertoPor,
    required this.reabiertoPorNombre,
    required this.reabiertoAt,
    required this.reabiertoAtFormato,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  ///
  /// Response format del backend:
  /// {
  ///   "fecha_id": "uuid",
  ///   "fecha_formato": "DD/MM/YYYY HH24:MI",
  ///   "lugar": "string",
  ///   "estado_anterior": "cerrada",
  ///   "estado_nuevo": "abierta",
  ///   "total_inscritos": 8,
  ///   "inscripciones_mantenidas": true,
  ///   "deudas_mantenidas": true,
  ///   "asignaciones_eliminadas": 0,
  ///   "reabierto_por": "uuid",
  ///   "reabierto_por_nombre": "string",
  ///   "reabierto_at": "timestamp",
  ///   "reabierto_at_formato": "DD/MM/YYYY HH24:MI"
  /// }
  factory ReabrirInscripcionesResponseModel.fromJson(
      Map<String, dynamic> json) {
    return ReabrirInscripcionesResponseModel(
      fechaId: json['fecha_id'] ?? '',
      fechaFormato: json['fecha_formato'] ?? '',
      lugar: json['lugar'] ?? '',
      estadoAnterior: json['estado_anterior'] ?? 'cerrada',
      estadoNuevo: json['estado_nuevo'] ?? 'abierta',
      totalInscritos: json['total_inscritos'] ?? 0,
      inscripcionesMantenidas: json['inscripciones_mantenidas'] ?? true,
      deudasMantenidas: json['deudas_mantenidas'] ?? true,
      asignacionesEliminadas: json['asignaciones_eliminadas'] ?? 0,
      reabiertoPor: json['reabierto_por'] ?? '',
      reabiertoPorNombre: json['reabierto_por_nombre'] ?? '',
      reabiertoAt: json['reabierto_at'] != null
          ? DateTime.parse(json['reabierto_at']).toLocal()
          : DateTime.now(),
      reabiertoAtFormato: json['reabierto_at_formato'] ?? '',
    );
  }

  /// Verifica si la reapertura fue exitosa
  bool get reaperturaExitosa => estadoNuevo == 'abierta';

  /// RN-005: Verifica si se eliminaron asignaciones de equipo
  bool get seEliminaronAsignaciones => asignacionesEliminadas > 0;

  @override
  List<Object?> get props => [
        fechaId,
        fechaFormato,
        lugar,
        estadoAnterior,
        estadoNuevo,
        totalInscritos,
        inscripcionesMantenidas,
        deudasMantenidas,
        asignacionesEliminadas,
        reabiertoPor,
        reabiertoPorNombre,
        reabiertoAt,
        reabiertoAtFormato,
      ];
}

/// Wrapper de respuesta completa del RPC reabrir_inscripciones
/// Sigue el formato estandar de response: {success, data, message}
class ReabrirInscripcionesRpcResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos de la respuesta (null si error)
  final ReabrirInscripcionesResponseModel? data;

  /// Mensaje descriptivo del servidor
  final String message;

  const ReabrirInscripcionesRpcResponseModel({
    required this.success,
    this.data,
    required this.message,
  });

  /// Crea instancia desde JSON completo del backend
  factory ReabrirInscripcionesRpcResponseModel.fromJson(
      Map<String, dynamic> json) {
    final dataJson = json['data'] as Map<String, dynamic>?;

    return ReabrirInscripcionesRpcResponseModel(
      success: json['success'] ?? false,
      data: dataJson != null
          ? ReabrirInscripcionesResponseModel.fromJson(dataJson)
          : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}
