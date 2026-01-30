import 'package:equatable/equatable.dart';

import '../../../data/models/cancelar_inscripcion_response_model.dart';
import '../../../data/models/verificar_cancelar_response_model.dart';

/// Estados del BLoC de cancelar inscripcion
/// E003-HU-007: Cancelar Inscripcion
abstract class CancelarInscripcionState extends Equatable {
  const CancelarInscripcionState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin verificacion ni cancelacion
class CancelarInscripcionInitial extends CancelarInscripcionState {
  const CancelarInscripcionInitial();
}

/// Estado de carga - Procesando verificacion o cancelacion
class CancelarInscripcionLoading extends CancelarInscripcionState {
  /// Indica si esta verificando (true) o cancelando (false)
  final bool esVerificacion;

  const CancelarInscripcionLoading({this.esVerificacion = true});

  @override
  List<Object?> get props => [esVerificacion];
}

/// CA-001, CA-002, CA-005: Estado con verificacion cargada
/// Muestra si el usuario puede cancelar y mensaje de confirmacion
class VerificacionCargada extends CancelarInscripcionState {
  /// Datos de la verificacion
  final VerificarCancelarDataModel verificacion;

  const VerificacionCargada({required this.verificacion});

  /// CA-001: El usuario puede cancelar su inscripcion
  bool get puedeCancelar => verificacion.puedeCancelar;

  /// RN-001: Cancelacion es libre (fecha abierta)
  bool get cancelacionLibre => verificacion.cancelacionLibre;

  /// RN-002: Fecha esta cerrada
  bool get fechaCerrada => verificacion.fechaCerrada;

  /// RN-003: La deuda sera anulada al cancelar
  bool get deudaSeraAnulada => verificacion.deudaSeraAnulada ?? false;

  /// CA-002: Mensaje de confirmacion para el dialogo
  String get mensajeConfirmacion =>
      verificacion.mensajeConfirmacion ??
      'Estas seguro de cancelar tu inscripcion?';

  /// CA-005: Mensaje si no puede cancelar
  String? get mensajeNoPuede => verificacion.mensaje;

  @override
  List<Object?> get props => [verificacion];
}

/// CA-003, CA-004: Estado de exito al cancelar inscripcion (jugador)
/// Muestra confirmacion y datos de la cancelacion
class CancelacionUsuarioExitosa extends CancelarInscripcionState {
  /// Datos de la cancelacion
  final CancelarInscripcionDataModel cancelacion;

  /// Mensaje de confirmacion del servidor
  final String message;

  const CancelacionUsuarioExitosa({
    required this.cancelacion,
    required this.message,
  });

  /// RN-003: La deuda fue anulada
  bool get deudaAnulada => cancelacion.deudaAnulada;

  /// RN-004: Asignacion de equipo fue eliminada
  bool get asignacionEliminada => cancelacion.asignacionEliminada;

  /// CA-004: Puede volver a inscribirse
  bool get puedeReinscribirse => cancelacion.puedeReinscribirse;

  @override
  List<Object?> get props => [cancelacion, message];
}

/// CA-006: Estado de exito al cancelar inscripcion (admin)
/// Muestra confirmacion y datos del jugador afectado
class CancelacionAdminExitosa extends CancelarInscripcionState {
  /// Datos de la cancelacion por admin
  final CancelarInscripcionAdminDataModel cancelacion;

  /// Mensaje de confirmacion del servidor
  final String message;

  const CancelacionAdminExitosa({
    required this.cancelacion,
    required this.message,
  });

  /// Nombre del jugador afectado
  String get nombreJugador => cancelacion.jugador.nombre;

  /// RN-003: La deuda fue anulada
  bool get deudaAnulada => cancelacion.deudaAnulada;

  /// RN-004: Asignacion de equipo fue eliminada
  bool get asignacionEliminada => cancelacion.asignacionEliminada;

  @override
  List<Object?> get props => [cancelacion, message];
}

/// Estado de error - Fallo en verificacion o cancelacion
class CancelarInscripcionError extends CancelarInscripcionState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  /// Valores posibles:
  /// - no_autenticado: Usuario no ha iniciado sesion
  /// - fecha_id_requerido: Parametro p_fecha_id es NULL
  /// - usuario_no_encontrado: Usuario no existe en tabla usuarios
  /// - fecha_no_encontrada: Fecha no existe
  /// - no_inscrito: Usuario no tiene inscripcion activa
  /// - fecha_cerrada: Inscripciones cerradas, debe contactar admin
  /// - sin_permisos: Usuario no es admin aprobado
  /// - inscripcion_id_requerido: Parametro p_inscripcion_id es NULL
  /// - inscripcion_no_encontrada: Inscripcion no existe
  /// - inscripcion_no_activa: Inscripcion ya esta cancelada
  /// - jugador_no_encontrado: Jugador de la inscripcion no existe
  /// - fecha_finalizada: No se puede modificar fecha finalizada
  final String? hint;

  const CancelarInscripcionError({
    required this.message,
    this.code,
    this.hint,
  });

  /// CA-005: Error por fecha cerrada
  bool get esFechaCerrada => hint == 'fecha_cerrada';

  /// Error por no estar inscrito
  bool get noInscrito => hint == 'no_inscrito';

  /// Error por inscripcion ya cancelada
  bool get inscripcionYaCancelada => hint == 'inscripcion_no_activa';

  /// Error por fecha finalizada
  bool get fechaFinalizada => hint == 'fecha_finalizada';

  /// Error por falta de permisos (admin)
  bool get sinPermisos => hint == 'sin_permisos';

  @override
  List<Object?> get props => [message, code, hint];
}
