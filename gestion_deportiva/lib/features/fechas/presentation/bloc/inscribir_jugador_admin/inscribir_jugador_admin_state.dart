part of 'inscribir_jugador_admin_bloc.dart';

/// E003-HU-011: Estados del BLoC de Inscribir Jugador como Admin
sealed class InscribirJugadorAdminState extends Equatable {
  const InscribirJugadorAdminState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class InscribirJugadorAdminInitial extends InscribirJugadorAdminState {
  const InscribirJugadorAdminInitial();
}

/// Cargando jugadores disponibles
class JugadoresDisponiblesCargando extends InscribirJugadorAdminState {
  const JugadoresDisponiblesCargando();
}

/// Jugadores disponibles cargados
/// CA-002: Lista de jugadores para selector
class JugadoresDisponiblesCargados extends InscribirJugadorAdminState {
  final List<JugadorDisponibleModel> jugadores;
  final int total;
  final String message;

  const JugadoresDisponiblesCargados({
    required this.jugadores,
    required this.total,
    required this.message,
  });

  @override
  List<Object?> get props => [jugadores, total, message];

  bool get estaVacio => jugadores.isEmpty;
}

/// Procesando inscripcion individual
class InscripcionAdminProcesando extends InscribirJugadorAdminState {
  final String jugadorNombre;

  const InscripcionAdminProcesando({required this.jugadorNombre});

  @override
  List<Object?> get props => [jugadorNombre];
}

/// Procesando inscripcion multiple
class InscripcionMultipleProcesando extends InscribirJugadorAdminState {
  final int totalJugadores;
  final int procesados;
  final String jugadorActual;

  const InscripcionMultipleProcesando({
    required this.totalJugadores,
    required this.procesados,
    required this.jugadorActual,
  });

  @override
  List<Object?> get props => [totalJugadores, procesados, jugadorActual];

  /// Progreso de 0 a 1
  double get progreso =>
      totalJugadores > 0 ? procesados / totalJugadores : 0.0;
}

/// Inscripcion exitosa (individual)
/// CA-004: Mensaje de confirmacion
class InscripcionAdminExitosa extends InscribirJugadorAdminState {
  final InscripcionAdminDataModel inscripcion;
  final String message;

  const InscripcionAdminExitosa({
    required this.inscripcion,
    required this.message,
  });

  @override
  List<Object?> get props => [inscripcion, message];
}

/// Inscripcion multiple exitosa
class InscripcionMultipleExitosa extends InscribirJugadorAdminState {
  final int totalInscritos;
  final int totalFallidos;
  final List<String> errores;
  final String message;

  const InscripcionMultipleExitosa({
    required this.totalInscritos,
    required this.totalFallidos,
    required this.errores,
    required this.message,
  });

  @override
  List<Object?> get props => [totalInscritos, totalFallidos, errores, message];

  bool get todosExitosos => totalFallidos == 0;
}

/// Error al cargar jugadores o inscribir
class InscribirJugadorAdminError extends InscribirJugadorAdminState {
  final String message;
  final String? hint;

  const InscribirJugadorAdminError({
    required this.message,
    this.hint,
  });

  @override
  List<Object?> get props => [message, hint];
}
