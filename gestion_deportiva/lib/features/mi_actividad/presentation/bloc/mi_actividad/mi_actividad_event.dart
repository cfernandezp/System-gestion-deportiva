import 'package:equatable/equatable.dart';

/// Eventos del bloc de Mi Actividad
/// E004-HU-008: Mi Actividad en Vivo
abstract class MiActividadEvent extends Equatable {
  const MiActividadEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar la actividad del jugador
/// CA-003: Pantalla Mi Actividad - Lista de todos los partidos
class CargarMiActividadEvent extends MiActividadEvent {
  const CargarMiActividadEvent();
}

/// Evento para actualizar la actividad desde Realtime
/// CA-009: Actualizacion en tiempo real
/// RN-006: Supabase Realtime
class ActualizarActividadRealtimeEvent extends MiActividadEvent {
  const ActualizarActividadRealtimeEvent();
}
