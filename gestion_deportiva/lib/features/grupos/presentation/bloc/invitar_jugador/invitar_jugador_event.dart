import 'package:equatable/equatable.dart';

/// Eventos del Bloc InvitarJugador
/// E001-HU-004: Invitar Jugador al Grupo
abstract class InvitarJugadorEvent extends Equatable {
  const InvitarJugadorEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001 a CA-004: Invitar jugador con celular
class InvitarJugadorSubmitEvent extends InvitarJugadorEvent {
  final String grupoId;
  final String celular;

  const InvitarJugadorSubmitEvent({
    required this.grupoId,
    required this.celular,
  });

  @override
  List<Object?> get props => [grupoId, celular];
}
