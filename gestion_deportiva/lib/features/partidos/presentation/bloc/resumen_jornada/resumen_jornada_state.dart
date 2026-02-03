import 'package:equatable/equatable.dart';

import '../../../data/models/resumen_jornada_model.dart';

/// Estados del BLoC de resumen de jornada
/// E004-HU-007: Resumen de Jornada
abstract class ResumenJornadaState extends Equatable {
  const ResumenJornadaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin datos cargados
class ResumenJornadaInitial extends ResumenJornadaState {
  const ResumenJornadaInitial();
}

/// Estado de carga - Obteniendo datos del servidor
class ResumenJornadaLoading extends ResumenJornadaState {
  const ResumenJornadaLoading();
}

/// Estado de exito con datos del resumen
/// CA-001: Tabla de posiciones
/// CA-002: Estadisticas de la jornada
/// CA-003: Lista de goleadores
class ResumenJornadaLoaded extends ResumenJornadaState {
  /// Respuesta completa con el resumen
  final ResumenJornadaModel resumen;

  const ResumenJornadaLoaded({required this.resumen});

  /// Informacion de la fecha
  FechaResumenModel? get fecha => resumen.fecha;

  /// Lista de partidos
  List<PartidoResumenModel> get partidos => resumen.partidos;

  /// CA-001: Tabla de posiciones
  List<TablaPosicionModel> get tablaPosiciones => resumen.tablaPosiciones;

  /// CA-003: Lista de goleadores
  List<GoleadorJornadaModel> get goleadores => resumen.goleadores;

  /// Goleador de la fecha (maximo anotador del dia)
  List<GoleadorFechaModel>? get goleadorFecha => resumen.goleadorFecha;

  /// CA-002: Estadisticas generales
  EstadisticasJornadaModel? get estadisticas => resumen.estadisticas;

  /// Indica si hay partidos en la fecha
  bool get hayPartidos => resumen.hayPartidos;

  /// Indica si hay tabla de posiciones
  bool get tieneTabla => resumen.tieneTabla;

  /// Indica si hay goleadores
  bool get tieneGoleadores => resumen.tieneGoleadores;

  /// Indica si hay goleador de la fecha
  bool get tieneGoleadorFecha => resumen.tieneGoleadorFecha;

  /// Indica si hay estadisticas
  bool get tieneEstadisticas => resumen.tieneEstadisticas;

  @override
  List<Object?> get props => [resumen];
}

/// Estado de refrescando - Actualizando datos con datos previos disponibles
class ResumenJornadaRefreshing extends ResumenJornadaState {
  /// Resumen previo mientras se refresca
  final ResumenJornadaModel resumenPrevio;

  const ResumenJornadaRefreshing({required this.resumenPrevio});

  @override
  List<Object?> get props => [resumenPrevio];
}

/// Estado de error
class ResumenJornadaError extends ResumenJornadaState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  final String? hint;

  /// ID de la fecha (para reintentar)
  final String? fechaId;

  const ResumenJornadaError({
    required this.message,
    this.code,
    this.hint,
    this.fechaId,
  });

  /// Error por usuario sin permisos
  bool get esSinPermisos => hint == 'sin_permisos';

  /// Error por fecha no encontrada
  bool get esFechaNoEncontrada => hint == 'fecha_no_encontrada';

  @override
  List<Object?> get props => [message, code, hint, fechaId];
}
