import 'package:equatable/equatable.dart';

/// Eventos del BLoC de cerrar/reabrir inscripciones
/// E003-HU-004: Cerrar Inscripciones
abstract class CerrarInscripcionesEvent extends Equatable {
  const CerrarInscripcionesEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001, CA-002: Evento para cerrar inscripciones de una fecha
/// RN-001: Solo admin aprobado
/// RN-002: Solo fechas con estado 'abierta'
/// RN-003: Advertencia si menos de 6 jugadores (no bloqueante)
/// RN-004: Registro de auditoria
class CerrarInscripcionesSubmitEvent extends CerrarInscripcionesEvent {
  /// ID de la fecha a cerrar (p_fecha_id)
  final String fechaId;

  const CerrarInscripcionesSubmitEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// CA-006: Evento para reabrir inscripciones de una fecha cerrada
/// RN-001: Solo admin aprobado
/// RN-005: Solo fechas con estado 'cerrada'
/// RN-006: Mantiene inscripciones y deudas existentes
class ReabrirInscripcionesSubmitEvent extends CerrarInscripcionesEvent {
  /// ID de la fecha a reabrir (p_fecha_id)
  final String fechaId;

  const ReabrirInscripcionesSubmitEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// Evento para reiniciar el estado del bloc
class CerrarInscripcionesResetEvent extends CerrarInscripcionesEvent {
  const CerrarInscripcionesResetEvent();
}
