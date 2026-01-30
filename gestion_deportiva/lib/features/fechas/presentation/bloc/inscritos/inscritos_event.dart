import 'package:equatable/equatable.dart';

/// Eventos del BLoC de inscritos a fechas
/// E003-HU-003: Ver Inscritos
abstract class InscritosEvent extends Equatable {
  const InscritosEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001: Evento para cargar la lista de inscritos de una fecha
/// Obtiene lista completa de jugadores anotados
class CargarInscritosEvent extends InscritosEvent {
  /// ID de la fecha a consultar
  final String fechaId;

  const CargarInscritosEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// CA-006: Evento cuando un inscrito es agregado (Realtime)
/// Dispara recarga de la lista
class InscritoAgregadoEvent extends InscritosEvent {
  /// ID de la fecha donde se agrego inscrito
  final String fechaId;

  const InscritoAgregadoEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// CA-006: Evento cuando un inscrito es removido (Realtime)
/// Dispara recarga de la lista
class InscritoRemovidoEvent extends InscritosEvent {
  /// ID de la fecha donde se removio inscrito
  final String fechaId;

  const InscritoRemovidoEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// RN-005: Evento para refrescar lista manualmente (pull-to-refresh)
/// Usado cuando falla conexion realtime
class RefrescarInscritosEvent extends InscritosEvent {
  const RefrescarInscritosEvent();
}

/// Evento para iniciar suscripcion realtime
/// RN-005: Actualizacion en tiempo real
class IniciarRealtimeEvent extends InscritosEvent {
  /// ID de la fecha a suscribirse
  final String fechaId;

  const IniciarRealtimeEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// Evento para detener suscripcion realtime
class DetenerRealtimeEvent extends InscritosEvent {
  const DetenerRealtimeEvent();
}

/// Evento para reiniciar el estado del bloc
class ResetInscritosEvent extends InscritosEvent {
  const ResetInscritosEvent();
}
