import 'package:equatable/equatable.dart';

/// Eventos del BLoC de inscripcion a fechas
/// E003-HU-002: Inscribirse a Fecha
abstract class InscripcionEvent extends Equatable {
  const InscripcionEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001: Evento para cargar el detalle de una fecha
/// Incluye lista de inscritos y estado de inscripcion del usuario
class CargarFechaDetalleEvent extends InscripcionEvent {
  /// ID de la fecha a cargar
  final String fechaId;

  const CargarFechaDetalleEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// CA-002, CA-003: Evento para inscribirse a una fecha
/// RN-001: Solo usuarios aprobados
/// RN-002: Solo fechas abiertas
/// RN-003: Inscripcion unica
/// RN-004: Genera deuda automatica
class InscribirseEvent extends InscripcionEvent {
  /// ID de la fecha a inscribirse
  final String fechaId;

  const InscribirseEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// CA-004: Evento para cancelar inscripcion
class CancelarInscripcionEvent extends InscripcionEvent {
  /// ID de la fecha de la cual cancelar inscripcion
  final String fechaId;

  const CancelarInscripcionEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// Evento para reiniciar el estado del bloc
class ResetInscripcionEvent extends InscripcionEvent {
  const ResetInscripcionEvent();
}

/// Evento para refrescar el detalle de la fecha actual
class RefrescarFechaDetalleEvent extends InscripcionEvent {
  const RefrescarFechaDetalleEvent();
}
