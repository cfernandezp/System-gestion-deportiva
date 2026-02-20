import 'package:equatable/equatable.dart';

/// E001-HU-002: Eventos del Bloc de Login
/// RN-001: Autenticacion por celular y contrasena
abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Enviar formulario de login
/// CA-001, CA-002, CA-003: Login con celular y contrasena
class LoginSubmitEvent extends LoginEvent {
  final String celular;
  final String password;

  const LoginSubmitEvent({
    required this.celular,
    required this.password,
  });

  @override
  List<Object?> get props => [celular, password];
}

/// Evento: Resetear estado del formulario
class LoginResetEvent extends LoginEvent {
  const LoginResetEvent();
}

/// Evento: Verificar bloqueo antes de intentar login
/// RN-002: Verificar si el celular esta bloqueado
class VerificarBloqueoEvent extends LoginEvent {
  final String celular;

  const VerificarBloqueoEvent({required this.celular});

  @override
  List<Object?> get props => [celular];
}
