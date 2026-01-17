import 'package:equatable/equatable.dart';

/// Eventos del PerfilJugadorBloc
/// E002-HU-004: Ver Perfil de Otro Jugador
abstract class PerfilJugadorEvent extends Equatable {
  const PerfilJugadorEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar el perfil de un jugador
/// CA-001: Acceso desde lista de jugadores
class CargarPerfilJugadorEvent extends PerfilJugadorEvent {
  final String jugadorId;

  const CargarPerfilJugadorEvent(this.jugadorId);

  @override
  List<Object?> get props => [jugadorId];
}

/// Evento para refrescar el perfil
class RefrescarPerfilJugadorEvent extends PerfilJugadorEvent {
  const RefrescarPerfilJugadorEvent();
}
