import 'package:equatable/equatable.dart';

import '../../../data/models/jugador_model.dart';

/// Estados del BLoC de jugadores
/// E002-HU-003: Lista de Jugadores
abstract class JugadoresState extends Equatable {
  const JugadoresState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class JugadoresInitial extends JugadoresState {
  const JugadoresInitial();
}

/// Cargando lista
class JugadoresLoading extends JugadoresState {
  const JugadoresLoading();
}

/// Lista cargada exitosamente
class JugadoresLoaded extends JugadoresState {
  final List<JugadorModel> jugadores;
  final int total;
  final FiltrosJugadores filtros;
  final String message;

  const JugadoresLoaded({
    required this.jugadores,
    required this.total,
    required this.filtros,
    required this.message,
  });

  @override
  List<Object?> get props => [jugadores, total, filtros, message];
}

/// Refrescando lista (mantiene datos actuales)
class JugadoresRefreshing extends JugadoresState {
  final List<JugadorModel> jugadoresActuales;
  final FiltrosJugadores filtros;

  const JugadoresRefreshing({
    required this.jugadoresActuales,
    required this.filtros,
  });

  @override
  List<Object?> get props => [jugadoresActuales, filtros];
}

/// Buscando (mantiene datos actuales)
class JugadoresBuscando extends JugadoresState {
  final List<JugadorModel> jugadoresActuales;
  final FiltrosJugadores filtros;

  const JugadoresBuscando({
    required this.jugadoresActuales,
    required this.filtros,
  });

  @override
  List<Object?> get props => [jugadoresActuales, filtros];
}

/// Error al cargar
class JugadoresError extends JugadoresState {
  final String message;
  final String? code;
  final String? hint;

  const JugadoresError({
    required this.message,
    this.code,
    this.hint,
  });

  @override
  List<Object?> get props => [message, code, hint];
}

/// RN-001: Lista vacia (sin jugadores aprobados)
class JugadoresVacio extends JugadoresState {
  final FiltrosJugadores filtros;
  final String message;

  const JugadoresVacio({
    required this.filtros,
    required this.message,
  });

  @override
  List<Object?> get props => [filtros, message];
}
