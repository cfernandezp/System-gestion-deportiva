import 'package:equatable/equatable.dart';

/// Eventos del BLoC de Mi Equipo
/// E003-HU-006: Ver Mi Equipo
abstract class MiEquipoEvent extends Equatable {
  const MiEquipoEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar mi equipo
/// CA-001, CA-002, CA-003, CA-005, CA-006
class CargarMiEquipoEvent extends MiEquipoEvent {
  final String fechaId;

  const CargarMiEquipoEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// Evento para cargar todos los equipos de la fecha
/// CA-004
class CargarEquiposFechaEvent extends MiEquipoEvent {
  final String fechaId;

  const CargarEquiposFechaEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// Evento para actualizar equipo desde Realtime
/// CA-007, RN-004
class ActualizarEquipoRealtimeEvent extends MiEquipoEvent {
  final String fechaId;

  const ActualizarEquipoRealtimeEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// Evento para iniciar suscripcion Realtime
/// RN-004
class IniciarRealtimeEvent extends MiEquipoEvent {
  final String fechaId;

  const IniciarRealtimeEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// Evento para detener suscripcion Realtime
class DetenerRealtimeEvent extends MiEquipoEvent {
  const DetenerRealtimeEvent();
}
