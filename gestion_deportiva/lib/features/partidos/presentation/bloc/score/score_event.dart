import 'package:equatable/equatable.dart';

/// Eventos del BLoC de Score en Vivo
/// E004-HU-004: Ver Score en Vivo
abstract class ScoreEvent extends Equatable {
  const ScoreEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001, CA-002, CA-005: Evento para cargar score inicial de un partido
class CargarScoreEvent extends ScoreEvent {
  /// ID del partido
  final String partidoId;

  const CargarScoreEvent({required this.partidoId});

  @override
  List<Object?> get props => [partidoId];
}

/// CA-003: Evento cuando se recibe actualizacion via realtime
/// Emitido cuando llega un nuevo gol por Supabase Realtime
class ScoreActualizadoEvent extends ScoreEvent {
  /// ID del partido
  final String partidoId;

  /// Datos del nuevo gol en formato JSON (de realtime payload)
  final Map<String, dynamic>? golData;

  const ScoreActualizadoEvent({
    required this.partidoId,
    this.golData,
  });

  @override
  List<Object?> get props => [partidoId, golData];
}

/// Evento interno para actualizar tiempo restante
class ActualizarTiempoScoreEvent extends ScoreEvent {
  const ActualizarTiempoScoreEvent();
}

/// Evento para limpiar flag de gol reciente (despues de 5 segundos)
class LimpiarGolRecienteEvent extends ScoreEvent {
  const LimpiarGolRecienteEvent();
}

/// Evento para iniciar suscripcion realtime
class SuscribirseRealtimeEvent extends ScoreEvent {
  /// ID del partido para filtrar eventos
  final String partidoId;

  const SuscribirseRealtimeEvent({required this.partidoId});

  @override
  List<Object?> get props => [partidoId];
}

/// Evento para cancelar suscripcion realtime
class DesuscribirseRealtimeEvent extends ScoreEvent {
  const DesuscribirseRealtimeEvent();
}

/// Evento para reiniciar el estado del bloc
class ResetScoreEvent extends ScoreEvent {
  const ResetScoreEvent();
}
