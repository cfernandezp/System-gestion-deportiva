import 'package:equatable/equatable.dart';

/// Eventos del Bloc RegistrarInvitado
/// E002-HU-008: Registrar Invitado en el Grupo
abstract class RegistrarInvitadoEvent extends Equatable {
  const RegistrarInvitadoEvent();

  @override
  List<Object?> get props => [];
}

/// Enviar formulario de registro de invitado
class RegistrarInvitadoSubmitEvent extends RegistrarInvitadoEvent {
  final String grupoId;
  final String nombre;

  const RegistrarInvitadoSubmitEvent({
    required this.grupoId,
    required this.nombre,
  });

  @override
  List<Object?> get props => [grupoId, nombre];
}
