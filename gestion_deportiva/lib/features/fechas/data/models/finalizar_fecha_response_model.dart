import 'package:equatable/equatable.dart';

/// Modelo de datos para el response de finalizacion de fecha
/// E003-HU-010: Finalizar Fecha
/// Mapea snake_case del backend a camelCase en Dart
class FinalizarFechaDataModel extends Equatable {
  /// UUID de la fecha finalizada
  final String fechaId;

  /// Fecha formateada (DD/MM/YYYY HH24:MI)
  final String fechaFormato;

  /// Lugar de la pichanga
  final String lugar;

  /// Estado anterior de la fecha (en_juego o cerrada)
  final String estadoAnterior;

  /// Estado nuevo de la fecha (siempre 'finalizada')
  final String estadoNuevo;

  /// Total de participantes con inscripcion activa
  final int totalParticipantes;

  /// Comentarios u observaciones opcionales del admin
  final String? comentarios;

  /// Flag que indica si hubo incidente
  final bool huboIncidente;

  /// Descripcion del incidente (obligatoria si huboIncidente es true)
  final String? descripcionIncidente;

  /// UUID del admin que finalizo
  final String finalizadoPor;

  /// Nombre del admin que finalizo
  final String finalizadoPorNombre;

  /// Timestamp de finalizacion (ISO 8601)
  final String finalizadoAt;

  /// Timestamp formateado (DD/MM/YYYY HH24:MI)
  final String finalizadoAtFormato;

  const FinalizarFechaDataModel({
    required this.fechaId,
    required this.fechaFormato,
    required this.lugar,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.totalParticipantes,
    this.comentarios,
    required this.huboIncidente,
    this.descripcionIncidente,
    required this.finalizadoPor,
    required this.finalizadoPorNombre,
    required this.finalizadoAt,
    required this.finalizadoAtFormato,
  });

  /// Factory para crear desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory FinalizarFechaDataModel.fromJson(Map<String, dynamic> json) {
    return FinalizarFechaDataModel(
      fechaId: json['fecha_id'] as String,
      fechaFormato: json['fecha_formato'] as String,
      lugar: json['lugar'] as String,
      estadoAnterior: json['estado_anterior'] as String,
      estadoNuevo: json['estado_nuevo'] as String,
      totalParticipantes: json['total_participantes'] as int,
      comentarios: json['comentarios'] as String?,
      huboIncidente: json['hubo_incidente'] as bool? ?? false,
      descripcionIncidente: json['descripcion_incidente'] as String?,
      finalizadoPor: json['finalizado_por'] as String,
      finalizadoPorNombre: json['finalizado_por_nombre'] as String,
      finalizadoAt: json['finalizado_at'] as String,
      finalizadoAtFormato: json['finalizado_at_formato'] as String,
    );
  }

  @override
  List<Object?> get props => [
        fechaId,
        fechaFormato,
        lugar,
        estadoAnterior,
        estadoNuevo,
        totalParticipantes,
        comentarios,
        huboIncidente,
        descripcionIncidente,
        finalizadoPor,
        finalizadoPorNombre,
        finalizadoAt,
        finalizadoAtFormato,
      ];
}

/// Modelo de response completo para finalizar fecha
/// E003-HU-010: Finalizar Fecha
class FinalizarFechaResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos de la fecha finalizada
  final FinalizarFechaDataModel data;

  /// Mensaje de confirmacion del servidor
  final String message;

  const FinalizarFechaResponseModel({
    required this.success,
    required this.data,
    required this.message,
  });

  /// Factory para crear desde JSON del backend
  factory FinalizarFechaResponseModel.fromJson(Map<String, dynamic> json) {
    return FinalizarFechaResponseModel(
      success: json['success'] as bool,
      data: FinalizarFechaDataModel.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String,
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}
