import 'package:equatable/equatable.dart';

/// Eventos del BLoC de cancelar inscripcion
/// E003-HU-007: Cancelar Inscripcion
abstract class CancelarInscripcionEvent extends Equatable {
  const CancelarInscripcionEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001, CA-002, CA-005: Evento para verificar si el usuario puede cancelar
/// Llama a RPC: verificar_puede_cancelar(p_fecha_id)
/// Retorna informacion sobre si puede cancelar y mensaje de confirmacion
class VerificarPuedeCancelarEvent extends CancelarInscripcionEvent {
  /// ID de la fecha a verificar
  final String fechaId;

  const VerificarPuedeCancelarEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// CA-003, CA-004, CA-007: Evento para cancelar inscripcion del usuario
/// RN-001: Solo si fecha esta abierta
/// RN-003: Deuda se anula automaticamente
/// RN-004: Asignacion de equipo se elimina
/// RN-005: Notifica a admin
/// RN-006: Soft delete con auditoria
class CancelarInscripcionUsuarioEvent extends CancelarInscripcionEvent {
  /// ID de la fecha de la cual cancelar inscripcion
  final String fechaId;

  const CancelarInscripcionUsuarioEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// CA-006: Evento para que admin cancele inscripcion de otro jugador
/// RN-002: Admin puede cancelar en cualquier estado pre-partido
/// RN-003: Admin decide si anular deuda
/// RN-004: Asignacion de equipo se elimina
/// RN-005: Notifica al jugador afectado
/// RN-006: Soft delete con auditoria
class CancelarInscripcionAdminEvent extends CancelarInscripcionEvent {
  /// ID de la inscripcion a cancelar
  final String inscripcionId;

  /// RN-003: Si true, anula la deuda pendiente del jugador
  final bool anularDeuda;

  const CancelarInscripcionAdminEvent({
    required this.inscripcionId,
    required this.anularDeuda,
  });

  @override
  List<Object?> get props => [inscripcionId, anularDeuda];
}

/// Evento para reiniciar el estado del bloc
class ResetCancelarInscripcionEvent extends CancelarInscripcionEvent {
  const ResetCancelarInscripcionEvent();
}
