import 'package:equatable/equatable.dart';

/// Eventos del BLoC de finalizar partido
/// E004-HU-005: Finalizar Partido
abstract class FinalizarPartidoEvent extends Equatable {
  const FinalizarPartidoEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001: Evento para solicitar finalizar partido
/// Si el tiempo no ha terminado, emite RequiereConfirmacion
class FinalizarPartidoRequested extends FinalizarPartidoEvent {
  /// ID del partido a finalizar
  final String partidoId;

  /// Indica si el tiempo del partido ya termino
  final bool tiempoTerminado;

  const FinalizarPartidoRequested({
    required this.partidoId,
    required this.tiempoTerminado,
  });

  @override
  List<Object?> get props => [partidoId, tiempoTerminado];
}

/// CA-006: Evento para confirmar finalizacion anticipada
/// El usuario confirmo que quiere terminar antes de tiempo
class ConfirmarFinalizacionAnticipada extends FinalizarPartidoEvent {
  /// ID del partido a finalizar
  final String partidoId;

  const ConfirmarFinalizacionAnticipada({required this.partidoId});

  @override
  List<Object?> get props => [partidoId];
}

/// Evento para cancelar la finalizacion
class CancelarFinalizacion extends FinalizarPartidoEvent {
  const CancelarFinalizacion();
}

/// Evento para reiniciar el estado del bloc
class ResetFinalizarPartido extends FinalizarPartidoEvent {
  const ResetFinalizarPartido();
}
