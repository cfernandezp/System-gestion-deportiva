part of 'inscribir_jugador_admin_bloc.dart';

/// E003-HU-011: Eventos del BLoC de Inscribir Jugador como Admin
sealed class InscribirJugadorAdminEvent extends Equatable {
  const InscribirJugadorAdminEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar jugadores disponibles para inscripcion
/// CA-002: Lista de jugadores aprobados no inscritos a esta fecha
class CargarJugadoresDisponiblesEvent extends InscribirJugadorAdminEvent {
  final String fechaId;

  const CargarJugadoresDisponiblesEvent({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// Inscribir jugador seleccionado (individual)
/// CA-003, CA-004: Validar y confirmar inscripcion
class InscribirJugadorEvent extends InscribirJugadorAdminEvent {
  final String fechaId;
  final String jugadorId;
  final String jugadorNombre;

  const InscribirJugadorEvent({
    required this.fechaId,
    required this.jugadorId,
    required this.jugadorNombre,
  });

  @override
  List<Object?> get props => [fechaId, jugadorId, jugadorNombre];
}

/// Inscribir multiples jugadores seleccionados
/// Procesa cada inscripcion en secuencia
class InscribirJugadoresMultipleEvent extends InscribirJugadorAdminEvent {
  final String fechaId;
  final List<JugadorParaInscribir> jugadores;

  const InscribirJugadoresMultipleEvent({
    required this.fechaId,
    required this.jugadores,
  });

  @override
  List<Object?> get props => [fechaId, jugadores];
}

/// Modelo auxiliar para inscripcion multiple
class JugadorParaInscribir extends Equatable {
  final String id;
  final String nombre;

  const JugadorParaInscribir({
    required this.id,
    required this.nombre,
  });

  @override
  List<Object?> get props => [id, nombre];
}

/// Reiniciar estado del BLoC
class ResetInscribirJugadorAdminEvent extends InscribirJugadorAdminEvent {
  const ResetInscribirJugadorAdminEvent();
}
