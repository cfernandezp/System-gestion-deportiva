import 'package:equatable/equatable.dart';

/// Eventos del BLoC de partido
/// E004-HU-001: Iniciar Partido
abstract class PartidoEvent extends Equatable {
  const PartidoEvent();

  @override
  List<Object?> get props => [];
}

/// CA-004: Evento para cargar partido activo de una fecha
class CargarPartidoActivoEvent extends PartidoEvent {
  /// ID de la fecha
  final String fechaId;

  const CargarPartidoActivoEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// CA-001, CA-002, CA-003: Evento para iniciar un nuevo partido
/// RN-001 a RN-006: Validaciones en backend
class IniciarPartidoEvent extends PartidoEvent {
  /// ID de la fecha
  final String fechaId;

  /// Color del equipo local (naranja, verde, azul, etc.)
  final String equipoLocal;

  /// Color del equipo visitante
  final String equipoVisitante;

  const IniciarPartidoEvent({
    required this.fechaId,
    required this.equipoLocal,
    required this.equipoVisitante,
  });

  @override
  List<Object?> get props => [fechaId, equipoLocal, equipoVisitante];
}

/// CA-005: Evento para pausar partido en curso
/// RN-007: Registro de pausa
class PausarPartidoEvent extends PartidoEvent {
  /// ID del partido a pausar
  final String partidoId;

  const PausarPartidoEvent({required this.partidoId});

  @override
  List<Object?> get props => [partidoId];
}

/// CA-005: Evento para reanudar partido pausado
/// RN-007: Registro de pausa
class ReanudarPartidoEvent extends PartidoEvent {
  /// ID del partido a reanudar
  final String partidoId;

  const ReanudarPartidoEvent({required this.partidoId});

  @override
  List<Object?> get props => [partidoId];
}

/// Evento interno para actualizar tiempo restante (countdown)
class ActualizarTiempoEvent extends PartidoEvent {
  const ActualizarTiempoEvent();
}

/// Evento para reiniciar estado del bloc
class ResetPartidoEvent extends PartidoEvent {
  const ResetPartidoEvent();
}
