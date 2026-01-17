import 'package:equatable/equatable.dart';

import '../../../data/models/jugador_perfil_model.dart';

/// Estados del PerfilJugadorBloc
/// E002-HU-004: Ver Perfil de Otro Jugador
abstract class PerfilJugadorState extends Equatable {
  const PerfilJugadorState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PerfilJugadorInitial extends PerfilJugadorState {
  const PerfilJugadorInitial();
}

/// Estado de carga
class PerfilJugadorLoading extends PerfilJugadorState {
  const PerfilJugadorLoading();
}

/// Estado con perfil cargado exitosamente
/// CA-002: Datos publicos visibles (foto, apodo, posicion, fecha ingreso)
/// CA-003: Datos privados ocultos (NO email, NO telefono)
/// CA-004: Estadisticas basicas (goles, partidos, puntos)
class PerfilJugadorLoaded extends PerfilJugadorState {
  final JugadorPerfilModel perfil;
  final String message;

  const PerfilJugadorLoaded({
    required this.perfil,
    required this.message,
  });

  @override
  List<Object?> get props => [perfil, message];
}

/// Estado de error
class PerfilJugadorError extends PerfilJugadorState {
  final String message;
  final String? code;
  final String? hint;

  const PerfilJugadorError({
    required this.message,
    this.code,
    this.hint,
  });

  @override
  List<Object?> get props => [message, code, hint];
}
