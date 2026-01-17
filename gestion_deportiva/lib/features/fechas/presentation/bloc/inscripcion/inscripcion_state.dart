import 'package:equatable/equatable.dart';

import '../../../data/models/fecha_detalle_model.dart';
import '../../../data/models/inscripcion_model.dart';

/// Estados del BLoC de inscripcion a fechas
/// E003-HU-002: Inscribirse a Fecha
abstract class InscripcionState extends Equatable {
  const InscripcionState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin datos cargados
class InscripcionInitial extends InscripcionState {
  const InscripcionInitial();
}

/// Estado de carga - Obteniendo datos del servidor
class InscripcionLoading extends InscripcionState {
  const InscripcionLoading();
}

/// CA-001, CA-006: Estado con detalle de fecha cargado
/// Muestra informacion de la fecha y lista de inscritos
class InscripcionFechaDetalleCargado extends InscripcionState {
  /// Detalle completo de la fecha con inscritos
  final FechaDetalleModel fechaDetalle;

  const InscripcionFechaDetalleCargado({required this.fechaDetalle});

  /// CA-002: Puede mostrar boton de inscripcion
  bool get puedeInscribirse => fechaDetalle.puedeInscribirse;

  /// CA-004: Puede mostrar boton de cancelar
  bool get puedeCancelar => fechaDetalle.puedeCancelar;

  /// CA-005: Inscripciones cerradas
  bool get inscripcionesCerradas => !fechaDetalle.inscripcionesAbiertas;

  /// CA-006: Total de inscritos
  int get totalInscritos => fechaDetalle.totalInscritos;

  @override
  List<Object?> get props => [fechaDetalle];
}

/// Estado de procesamiento - Procesando inscripcion o cancelacion
class InscripcionProcesando extends InscripcionState {
  /// Detalle de la fecha actual (para mantener UI)
  final FechaDetalleModel? fechaDetalle;

  /// Indica si esta inscribiendo (true) o cancelando (false)
  final bool esInscripcion;

  const InscripcionProcesando({
    this.fechaDetalle,
    required this.esInscripcion,
  });

  @override
  List<Object?> get props => [fechaDetalle, esInscripcion];
}

/// CA-003: Estado de exito al inscribirse
/// Muestra mensaje de confirmacion y datos de inscripcion
class InscripcionExitosa extends InscripcionState {
  /// Datos de la inscripcion creada
  final InscripcionModel inscripcion;

  /// Mensaje de confirmacion del servidor
  final String message;

  /// Detalle actualizado de la fecha
  final FechaDetalleModel? fechaDetalle;

  const InscripcionExitosa({
    required this.inscripcion,
    required this.message,
    this.fechaDetalle,
  });

  /// RN-004: Indica si se genero deuda
  bool get deudaGenerada => inscripcion.deudaGenerada;

  @override
  List<Object?> get props => [inscripcion, message, fechaDetalle];
}

/// CA-004: Estado de exito al cancelar inscripcion
class CancelacionExitosa extends InscripcionState {
  /// Mensaje de confirmacion del servidor
  final String message;

  /// Detalle actualizado de la fecha
  final FechaDetalleModel? fechaDetalle;

  const CancelacionExitosa({
    required this.message,
    this.fechaDetalle,
  });

  @override
  List<Object?> get props => [message, fechaDetalle];
}

/// Estado de error - Fallo en alguna operacion
class InscripcionError extends InscripcionState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  /// Valores posibles:
  /// - no_autenticado: Usuario no ha iniciado sesion
  /// - usuario_no_aprobado: Usuario no esta aprobado (RN-001)
  /// - fecha_no_encontrada: Fecha no existe
  /// - inscripciones_cerradas: Fecha no esta abierta (RN-002)
  /// - ya_inscrito: Usuario ya inscrito (RN-003)
  /// - no_inscrito: Intento cancelar sin estar inscrito
  /// - capacidad_llena: No hay lugares disponibles
  final String? hint;

  /// Detalle de la fecha (si se tenia antes del error)
  final FechaDetalleModel? fechaDetalle;

  const InscripcionError({
    required this.message,
    this.code,
    this.hint,
    this.fechaDetalle,
  });

  /// RN-001: Error por usuario no aprobado
  bool get esUsuarioNoAprobado => hint == 'usuario_no_aprobado';

  /// RN-002: Error por inscripciones cerradas
  bool get esInscripcionesCerradas => hint == 'inscripciones_cerradas';

  /// RN-003: Error por ya estar inscrito
  bool get esYaInscrito => hint == 'ya_inscrito';

  /// Error por capacidad llena
  bool get esCapacidadLlena => hint == 'capacidad_llena';

  @override
  List<Object?> get props => [message, code, hint, fechaDetalle];
}
