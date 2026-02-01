import 'package:equatable/equatable.dart';

import '../../../data/models/iniciar_fecha_response_model.dart';

/// Estados del BLoC de iniciar fecha
/// E003-HU-012: Iniciar Fecha
abstract class IniciarFechaState extends Equatable {
  const IniciarFechaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class IniciarFechaInitial extends IniciarFechaState {
  const IniciarFechaInitial();
}

/// Estado de carga mientras se procesa el inicio
class IniciarFechaLoading extends IniciarFechaState {
  const IniciarFechaLoading();
}

/// Estado de exito cuando la fecha se inicio correctamente
/// CA-004: Estado cambia a en_juego
/// CA-006: Notificaciones enviadas a jugadores
class IniciarFechaSuccess extends IniciarFechaState {
  /// Datos de la fecha iniciada
  final IniciarFechaDataModel data;

  /// Mensaje de exito del servidor
  final String message;

  const IniciarFechaSuccess({
    required this.data,
    required this.message,
  });

  /// Indica si hay warning por falta de equipos
  bool get tieneWarning => data.warningSinEquipos;

  /// Cantidad de notificaciones enviadas
  int get notificacionesEnviadas => data.notificacionesEnviadas;

  @override
  List<Object?> get props => [data, message];
}

/// Estado de error cuando falla el inicio
class IniciarFechaError extends IniciarFechaState {
  /// Mensaje de error
  final String message;

  /// Codigo de error del servidor
  final String? code;

  /// Hint para identificar el tipo de error
  final String? hint;

  const IniciarFechaError({
    required this.message,
    this.code,
    this.hint,
  });

  /// Verifica si el error es por permisos
  bool get esSinPermisos => hint == 'sin_permisos';

  /// Verifica si el error es por estado invalido
  bool get esEstadoInvalido => hint == 'estado_invalido';

  /// Verifica si el error es porque la fecha no existe
  bool get esFechaNoEncontrada => hint == 'fecha_no_encontrada';

  @override
  List<Object?> get props => [message, code, hint];
}
