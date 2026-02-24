import 'package:equatable/equatable.dart';

/// Eventos del Bloc PromoverInvitado
/// E002-HU-009: Promover Invitado a Jugador
abstract class PromoverInvitadoEvent extends Equatable {
  const PromoverInvitadoEvent();

  @override
  List<Object?> get props => [];
}

/// Enviar formulario de promocion de invitado a jugador
class PromoverInvitadoSubmitEvent extends PromoverInvitadoEvent {
  final String grupoId;
  final String miembroId;
  final String celular;

  const PromoverInvitadoSubmitEvent({
    required this.grupoId,
    required this.miembroId,
    required this.celular,
  });

  @override
  List<Object?> get props => [grupoId, miembroId, celular];
}
