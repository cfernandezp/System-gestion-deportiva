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

  /// Valor de puede_inscribirse del backend (logica correcta del servidor)
  final bool puedeInscribirseBackend;

  const FechaDetalleModel({
    required this.fecha,
    required this.inscritos,
    required this.totalInscritos,
    required this.capacidadMaxima,
    required this.usuarioInscrito,
    this.inscripcionIdUsuario,
    required this.inscripcionesAbiertas,
    this.mensajeEstado,
    this.puedeInscribirseBackend = false,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  /// Estructura esperada del RPC obtener_fecha_detalle:
  /// {
  ///   "fecha": { "estado": "abierta", ... },
  ///   "inscripciones": { "total": N, "lista": [...] },
  ///   "usuario_actual": { "esta_inscrito": bool, "puede_inscribirse": bool, ... }
  /// }
  factory FechaDetalleModel.fromJson(Map<String, dynamic> json) {
    // Obtener datos de fecha
    final fechaJson = json['fecha'] as Map<String, dynamic>? ?? {};
    final fecha = FechaModel.fromJson(fechaJson);

    // Obtener datos de inscripciones
    final inscripcionesJson = json['inscripciones'] as Map<String, dynamic>? ?? {};
    final inscritosJson = inscripcionesJson['lista'] as List<dynamic>? ?? [];
    final inscritos = inscritosJson
        .map((e) => InscritoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final totalInscritos = inscripcionesJson['total'] as int? ?? inscritos.length;

    // Obtener datos del usuario actual
    final usuarioActualJson = json['usuario_actual'] as Map<String, dynamic>? ?? {};
    final usuarioInscrito = usuarioActualJson['esta_inscrito'] as bool? ?? false;
    final inscripcionIdUsuario = usuarioActualJson['inscripcion_id'] as String?;
    // Usar puede_inscribirse del backend que tiene la logica correcta
    final puedeInscribirseBackend = usuarioActualJson['puede_inscribirse'] as bool? ?? false;

    // Determinar si inscripciones estan abiertas basado en estado de fecha
    final estadoFecha = fechaJson['estado'] as String? ?? '';
    final inscripcionesAbiertas = estadoFecha == 'abierta';

    // Capacidad maxima: 0 significa "sin limite" (usar valor alto)
    // Por defecto 18 jugadores es un numero tipico para pichangas
    final capacidadMaxima = json['capacidad_maxima'] as int? ?? 0;

    return FechaDetalleModel(
      fecha: fecha,
      inscritos: inscritos,
      totalInscritos: totalInscritos,
      capacidadMaxima: capacidadMaxima,
      usuarioInscrito: usuarioInscrito,
      inscripcionIdUsuario: inscripcionIdUsuario,
      inscripcionesAbiertas: inscripcionesAbiertas,
      mensajeEstado: _generarMensajeEstado(estadoFecha, usuarioInscrito),
      puedeInscribirseBackend: puedeInscribirseBackend,
    );
  }

  /// Genera mensaje informativo basado en estado
  static String? _generarMensajeEstado(String estado, bool inscrito) {
    if (inscrito) return null;
    switch (estado) {
      case 'cerrada':
        return 'Las inscripciones estan cerradas.';
      case 'en_juego':
        return 'La pichanga esta en curso.';
      case 'finalizada':
        return 'Esta pichanga ya termino.';
      case 'cancelada':
        return 'Esta pichanga fue cancelada.';
      default:
        return null;
    }
  }

  /// CA-006: Lugares disponibles
  /// Si capacidadMaxima es 0, significa "sin limite"
  int get lugaresDisponibles =>
      capacidadMaxima > 0 ? capacidadMaxima - totalInscritos : 999;

  /// Verifica si hay lugares disponibles
  /// Si no hay limite (capacidadMaxima = 0), siempre hay lugares
  bool get hayLugaresDisponibles =>
      capacidadMaxima == 0 || lugaresDisponibles > 0;

  /// Verifica si esta lleno
  /// Solo puede estar lleno si hay un limite definido (capacidadMaxima > 0)
  bool get estaLleno =>
      capacidadMaxima > 0 && totalInscritos >= capacidadMaxima;

  /// CA-002: Puede inscribirse - usa la logica del backend
  bool get puedeInscribirse => puedeInscribirseBackend;

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
        puedeInscribirseBackend,
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
