import 'package:equatable/equatable.dart';

/// Eventos del Bloc ActivacionCuenta
/// E001-HU-005: Activacion de Cuenta de Jugador Invitado
abstract class ActivacionCuentaEvent extends Equatable {
  const ActivacionCuentaEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001, CA-002, CA-004: Verificar si el celular tiene invitacion pendiente
class VerificarInvitacionEvent extends ActivacionCuentaEvent {
  final String celular;

  const VerificarInvitacionEvent({required this.celular});

  @override
  List<Object?> get props => [celular];
}

/// Resetear al estado inicial (volver al paso 1)
class ResetActivacionEvent extends ActivacionCuentaEvent {
  const ResetActivacionEvent();
}

/// CA-001, CA-005, CA-006: Activar cuenta con nombre y contrasena
class ActivarCuentaEvent extends ActivacionCuentaEvent {
  final String celular;
  final String nombreCompleto;
  final String password;

  const ActivarCuentaEvent({
    required this.celular,
    required this.nombreCompleto,
    required this.password,
  });

  @override
  List<Object?> get props => [celular, nombreCompleto, password];
}
