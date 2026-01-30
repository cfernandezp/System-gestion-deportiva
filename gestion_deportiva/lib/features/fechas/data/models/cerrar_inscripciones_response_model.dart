import 'package:equatable/equatable.dart';

/// Modelo de respuesta para cerrar_inscripciones RPC
/// E003-HU-004: Cerrar Inscripciones
///
/// Criterios de Aceptacion:
/// - CA-002: Resumen con cantidad de inscritos y formato de juego
/// - CA-003: Advertencia si hay menos de 6 jugadores
/// - CA-004: Estado actualizado a 'cerrada'
/// - CA-007: Notificacion de cierre a inscritos
///
/// Reglas de Negocio:
/// - RN-001: Solo admin aprobado puede cerrar
/// - RN-002: Solo fechas con estado 'abierta'
/// - RN-003: Advertencia si menos de 6 jugadores (no bloqueante)
/// - RN-004: Registro de auditoria (cerrado_por, cerrado_at)
class CerrarInscripcionesResponseModel extends Equatable {
  /// ID de la fecha cerrada
  final String fechaId;

  /// Fecha formateada (DD/MM/YYYY HH24:MI)
  final String fechaFormato;

  /// Lugar de la pichanga
  final String lugar;

  /// Estado anterior de la fecha ('abierta')
  final String estadoAnterior;

  /// Estado nuevo de la fecha ('cerrada')
  final String estadoNuevo;

  /// CA-002: Total de jugadores inscritos
  final int totalInscritos;

  /// CA-002: Formato de juego ("2 equipos" o "3 equipos")
  final String formatoJuego;

  /// CA-003: Advertencia si hay menos de 6 jugadores (RN-003)
  final bool advertenciaMinimo;

  /// ID del admin que cerro las inscripciones (RN-004)
  final String cerradoPor;

  /// Nombre del admin que cerro
  final String cerradoPorNombre;

  /// Timestamp de cierre (UTC)
  final DateTime cerradoAt;

  /// Timestamp de cierre formateado (DD/MM/YYYY HH24:MI)
  final String cerradoAtFormato;

  const CerrarInscripcionesResponseModel({
    required this.fechaId,
    required this.fechaFormato,
    required this.lugar,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.totalInscritos,
    required this.formatoJuego,
    required this.advertenciaMinimo,
    required this.cerradoPor,
    required this.cerradoPorNombre,
    required this.cerradoAt,
    required this.cerradoAtFormato,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  ///
  /// Response format del backend:
  /// {
  ///   "fecha_id": "uuid",
  ///   "fecha_formato": "DD/MM/YYYY HH24:MI",
  ///   "lugar": "string",
  ///   "estado_anterior": "abierta",
  ///   "estado_nuevo": "cerrada",
  ///   "total_inscritos": 8,
  ///   "formato_juego": "2 equipos",
  ///   "advertencia_minimo": false,
  ///   "cerrado_por": "uuid",
  ///   "cerrado_por_nombre": "string",
  ///   "cerrado_at": "timestamp",
  ///   "cerrado_at_formato": "DD/MM/YYYY HH24:MI"
  /// }
  factory CerrarInscripcionesResponseModel.fromJson(Map<String, dynamic> json) {
    return CerrarInscripcionesResponseModel(
      fechaId: json['fecha_id'] ?? '',
      fechaFormato: json['fecha_formato'] ?? '',
      lugar: json['lugar'] ?? '',
      estadoAnterior: json['estado_anterior'] ?? 'abierta',
      estadoNuevo: json['estado_nuevo'] ?? 'cerrada',
      totalInscritos: json['total_inscritos'] ?? 0,
      formatoJuego: json['formato_juego'] ?? '',
      advertenciaMinimo: json['advertencia_minimo'] ?? false,
      cerradoPor: json['cerrado_por'] ?? '',
      cerradoPorNombre: json['cerrado_por_nombre'] ?? '',
      cerradoAt: json['cerrado_at'] != null
          ? DateTime.parse(json['cerrado_at']).toLocal()
          : DateTime.now(),
      cerradoAtFormato: json['cerrado_at_formato'] ?? '',
    );
  }

  /// CA-003: Verifica si hay pocos jugadores (menos del minimo recomendado)
  /// RN-003: Minimo recomendado = 6 jugadores
  bool get tienePocosJugadores => advertenciaMinimo;

  /// Verifica si el cierre fue exitoso
  bool get cierreExitoso => estadoNuevo == 'cerrada';

  @override
  List<Object?> get props => [
        fechaId,
        fechaFormato,
        lugar,
        estadoAnterior,
        estadoNuevo,
        totalInscritos,
        formatoJuego,
        advertenciaMinimo,
        cerradoPor,
        cerradoPorNombre,
        cerradoAt,
        cerradoAtFormato,
      ];
}

/// Wrapper de respuesta completa del RPC cerrar_inscripciones
/// Sigue el formato estandar de response: {success, data, message}
class CerrarInscripcionesRpcResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos de la respuesta (null si error)
  final CerrarInscripcionesResponseModel? data;

  /// Mensaje descriptivo del servidor
  final String message;

  const CerrarInscripcionesRpcResponseModel({
    required this.success,
    this.data,
    required this.message,
  });

  /// Crea instancia desde JSON completo del backend
  factory CerrarInscripcionesRpcResponseModel.fromJson(
      Map<String, dynamic> json) {
    final dataJson = json['data'] as Map<String, dynamic>?;

    return CerrarInscripcionesRpcResponseModel(
      success: json['success'] ?? false,
      data: dataJson != null
          ? CerrarInscripcionesResponseModel.fromJson(dataJson)
          : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}
