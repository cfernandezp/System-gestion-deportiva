import 'package:equatable/equatable.dart';

import '../../../data/models/cerrar_inscripciones_response_model.dart';
import '../../../data/models/reabrir_inscripciones_response_model.dart';

/// Estados del BLoC de cerrar/reabrir inscripciones
/// E003-HU-004: Cerrar Inscripciones
abstract class CerrarInscripcionesState extends Equatable {
  const CerrarInscripcionesState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin operacion en progreso
class CerrarInscripcionesInitial extends CerrarInscripcionesState {
  const CerrarInscripcionesInitial();
}

/// Estado de carga al cerrar inscripciones
class CerrarInscripcionesLoading extends CerrarInscripcionesState {
  const CerrarInscripcionesLoading();
}

/// Estado de carga al reabrir inscripciones
class ReabrirInscripcionesLoading extends CerrarInscripcionesState {
  const ReabrirInscripcionesLoading();
}

/// CA-002, CA-003, CA-004: Estado de exito al cerrar inscripciones
/// Contiene resumen con total inscritos y formato de juego
class CerrarInscripcionesSuccess extends CerrarInscripcionesState {
  /// Datos de la respuesta del cierre
  final CerrarInscripcionesResponseModel data;

  /// Mensaje de confirmacion del servidor
  final String message;

  const CerrarInscripcionesSuccess({
    required this.data,
    required this.message,
  });

  /// CA-002: Total de jugadores inscritos
  int get totalInscritos => data.totalInscritos;

  /// CA-002: Formato de juego ("2 equipos" o "3 equipos")
  String get formatoJuego => data.formatoJuego;

  /// CA-003: Advertencia si hay menos de 6 jugadores (RN-003)
  bool get advertenciaMinimo => data.advertenciaMinimo;

  /// Nombre del admin que cerro
  String get cerradoPorNombre => data.cerradoPorNombre;

  /// Timestamp de cierre formateado
  String get cerradoAtFormato => data.cerradoAtFormato;

  @override
  List<Object?> get props => [data, message];
}

/// CA-006: Estado de exito al reabrir inscripciones
/// RN-005, RN-006: Mantiene inscripciones y elimina asignaciones
class ReabrirInscripcionesSuccess extends CerrarInscripcionesState {
  /// Datos de la respuesta de reapertura
  final ReabrirInscripcionesResponseModel data;

  /// Mensaje de confirmacion del servidor
  final String message;

  const ReabrirInscripcionesSuccess({
    required this.data,
    required this.message,
  });

  /// Total de jugadores inscritos (se mantienen)
  int get totalInscritos => data.totalInscritos;

  /// RN-005: Cantidad de asignaciones de equipo eliminadas
  int get asignacionesEliminadas => data.asignacionesEliminadas;

  /// RN-006: Indica que las inscripciones se mantuvieron
  bool get inscripcionesMantenidas => data.inscripcionesMantenidas;

  /// RN-006: Indica que las deudas se mantuvieron
  bool get deudasMantenidas => data.deudasMantenidas;

  /// Nombre del admin que reabrio
  String get reabiertoPorNombre => data.reabiertoPorNombre;

  /// Timestamp de reapertura formateado
  String get reabiertoAtFormato => data.reabiertoAtFormato;

  @override
  List<Object?> get props => [data, message];
}

/// Estado de error al cerrar inscripciones
/// Maneja errores de backend con hints descriptivos
class CerrarInscripcionesError extends CerrarInscripcionesState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  /// Valores posibles segun HU-004:
  /// - no_autenticado: Usuario no ha iniciado sesion
  /// - fecha_id_requerido: No se proporciono ID de fecha
  /// - usuario_no_encontrado: Usuario no existe
  /// - sin_permisos: No es admin aprobado (RN-001)
  /// - fecha_no_encontrada: Fecha con ese ID no existe
  /// - estado_invalido: Fecha no tiene estado 'abierta' (RN-002)
  final String? hint;

  const CerrarInscripcionesError({
    required this.message,
    this.code,
    this.hint,
  });

  /// RN-001: Verifica si el error es de permisos
  bool get esSinPermisos => hint == 'sin_permisos';

  /// RN-002: Verifica si el estado es invalido para cerrar
  bool get esEstadoInvalido => hint == 'estado_invalido';

  /// Verifica si la fecha no existe
  bool get esFechaNoEncontrada => hint == 'fecha_no_encontrada';

  /// Verifica si no esta autenticado
  bool get esNoAutenticado => hint == 'no_autenticado';

  @override
  List<Object?> get props => [message, code, hint];
}

/// Estado de error al reabrir inscripciones
/// Maneja errores de backend con hints descriptivos
class ReabrirInscripcionesError extends CerrarInscripcionesState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  /// Valores posibles segun HU-004:
  /// - no_autenticado: Usuario no ha iniciado sesion
  /// - fecha_id_requerido: No se proporciono ID de fecha
  /// - usuario_no_encontrado: Usuario no existe
  /// - sin_permisos: No es admin aprobado (RN-001)
  /// - fecha_no_encontrada: Fecha con ese ID no existe
  /// - estado_invalido: Fecha no tiene estado 'cerrada' (RN-005)
  final String? hint;

  const ReabrirInscripcionesError({
    required this.message,
    this.code,
    this.hint,
  });

  /// RN-001: Verifica si el error es de permisos
  bool get esSinPermisos => hint == 'sin_permisos';

  /// RN-005: Verifica si el estado es invalido para reabrir
  bool get esEstadoInvalido => hint == 'estado_invalido';

  /// Verifica si la fecha no existe
  bool get esFechaNoEncontrada => hint == 'fecha_no_encontrada';

  /// Verifica si no esta autenticado
  bool get esNoAutenticado => hint == 'no_autenticado';

  @override
  List<Object?> get props => [message, code, hint];
}
