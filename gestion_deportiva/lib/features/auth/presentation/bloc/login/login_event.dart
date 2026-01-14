import 'package:equatable/equatable.dart';

/// Eventos del Bloc de Login
/// HU-002: Inicio de Sesion
abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Enviar formulario de login
/// CA-002: Login exitoso
/// CA-003: Credenciales invalidas
class LoginSubmitEvent extends LoginEvent {
  final String email;
  final String password;

  const LoginSubmitEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Evento: Resetear estado del formulario
class LoginResetEvent extends LoginEvent {
  const LoginResetEvent();
}

/// Evento: Verificar bloqueo antes de intentar login
/// RN-007: Verificar si el email esta bloqueado
class VerificarBloqueoEvent extends LoginEvent {
  final String email;

  const VerificarBloqueoEvent({required this.email});

  @override
  List<Object?> get props => [email];
}
