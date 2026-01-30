import 'package:equatable/equatable.dart';

/// Eventos del BLoC de asignaciones de equipos
/// E003-HU-005: Asignar Equipos
abstract class AsignacionesEvent extends Equatable {
  const AsignacionesEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001: Evento para cargar asignaciones de una fecha
/// Obtiene lista de jugadores inscritos y equipos disponibles
class CargarAsignacionesEvent extends AsignacionesEvent {
  /// ID de la fecha (p_fecha_id)
  final String fechaId;

  const CargarAsignacionesEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// CA-004, CA-005: Evento para asignar un jugador a un equipo
/// RN-001: Solo admin aprobado
/// RN-002: Solo fechas con estado 'cerrada'
/// RN-004: Valida color de equipo
/// RN-008: Permite modificar antes de iniciar
class AsignarEquipoEvent extends AsignacionesEvent {
  /// ID de la fecha (p_fecha_id)
  final String fechaId;

  /// ID del usuario a asignar (p_usuario_id)
  final String usuarioId;

  /// Color del equipo (p_equipo): 'naranja', 'verde', 'azul'
  final String equipo;

  const AsignarEquipoEvent({
    required this.fechaId,
    required this.usuarioId,
    required this.equipo,
  });

  @override
  List<Object?> get props => [fechaId, usuarioId, equipo];
}

/// CA-007: Evento para confirmar todas las asignaciones
/// RN-005: Todos los jugadores deben tener equipo
/// RN-006: Valida balance de equipos (advertencia)
/// RN-007: Envia notificaciones a jugadores
class ConfirmarEquiposEvent extends AsignacionesEvent {
  /// ID de la fecha (p_fecha_id)
  final String fechaId;

  const ConfirmarEquiposEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// Evento para reiniciar el estado del bloc
class ResetAsignacionesEvent extends AsignacionesEvent {
  const ResetAsignacionesEvent();
}
