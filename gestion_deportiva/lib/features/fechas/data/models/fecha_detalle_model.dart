import 'package:equatable/equatable.dart';

import 'fecha_model.dart';
import 'inscrito_model.dart';

/// Modelo de detalle de fecha con lista de inscritos
/// E003-HU-002: CA-001, CA-002, CA-004, CA-005, CA-006
/// Incluye todos los datos necesarios para la pantalla de detalle
class FechaDetalleModel extends Equatable {
  /// Datos basicos de la fecha
  final FechaModel fecha;

  /// CA-006: Lista de jugadores inscritos
  final List<InscritoModel> inscritos;

  /// CA-006: Total de inscritos confirmados
  final int totalInscritos;

  /// Capacidad maxima de jugadores
  final int capacidadMaxima;

  /// CA-004: Indica si el usuario actual esta inscrito
  final bool usuarioInscrito;

  /// ID de inscripcion del usuario actual (si esta inscrito)
  final String? inscripcionIdUsuario;

  /// CA-002, CA-005: Indica si las inscripciones estan abiertas
  final bool inscripcionesAbiertas;

  /// Mensaje informativo sobre estado de inscripciones
  final String? mensajeEstado;

  const FechaDetalleModel({
    required this.fecha,
    required this.inscritos,
    required this.totalInscritos,
    required this.capacidadMaxima,
    required this.usuarioInscrito,
    this.inscripcionIdUsuario,
    required this.inscripcionesAbiertas,
    this.mensajeEstado,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory FechaDetalleModel.fromJson(Map<String, dynamic> json) {
    // Parsear lista de inscritos
    final inscritosJson = json['inscritos'] as List<dynamic>? ?? [];
    final inscritos = inscritosJson
        .map((e) => InscritoModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return FechaDetalleModel(
      fecha: FechaModel.fromJson(json['fecha'] as Map<String, dynamic>? ?? json),
      inscritos: inscritos,
      totalInscritos: json['total_inscritos'] ?? inscritos.length,
      capacidadMaxima: json['capacidad_maxima'] ?? 0,
      usuarioInscrito: json['usuario_inscrito'] ?? false,
      inscripcionIdUsuario: json['inscripcion_id_usuario'],
      inscripcionesAbiertas: json['inscripciones_abiertas'] ?? false,
      mensajeEstado: json['mensaje_estado'],
    );
  }

  /// CA-006: Lugares disponibles
  int get lugaresDisponibles => capacidadMaxima - totalInscritos;

  /// Verifica si hay lugares disponibles
  bool get hayLugaresDisponibles => lugaresDisponibles > 0;

  /// Verifica si esta lleno
  bool get estaLleno => lugaresDisponibles <= 0;

  /// CA-002: Puede inscribirse (abierta, hay lugar, no inscrito)
  bool get puedeInscribirse =>
      inscripcionesAbiertas && hayLugaresDisponibles && !usuarioInscrito;

  /// CA-004: Puede cancelar (inscrito y abierta)
  bool get puedeCancelar => usuarioInscrito && inscripcionesAbiertas;

  /// Porcentaje de ocupacion
  double get porcentajeOcupacion =>
      capacidadMaxima > 0 ? (totalInscritos / capacidadMaxima) * 100 : 0;

  /// Descripcion de capacidad para mostrar
  String get descripcionCapacidad => '$totalInscritos / $capacidadMaxima';

  @override
  List<Object?> get props => [
        fecha,
        inscritos,
        totalInscritos,
        capacidadMaxima,
        usuarioInscrito,
        inscripcionIdUsuario,
        inscripcionesAbiertas,
        mensajeEstado,
      ];
}

/// Modelo de respuesta del detalle de fecha
/// E003-HU-002: obtener_fecha_detalle RPC
class FechaDetalleResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Mensaje del servidor
  final String message;

  /// Datos del detalle de la fecha
  final FechaDetalleModel? data;

  const FechaDetalleResponseModel({
    required this.success,
    required this.message,
    this.data,
  });

  /// Crea instancia desde JSON del backend
  factory FechaDetalleResponseModel.fromJson(Map<String, dynamic> json) {
    return FechaDetalleResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? FechaDetalleModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
