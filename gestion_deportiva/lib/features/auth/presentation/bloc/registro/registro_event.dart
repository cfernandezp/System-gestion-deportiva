import 'package:equatable/equatable.dart';

/// Eventos del Bloc de Registro
abstract class RegistroEvent extends Equatable {
  const RegistroEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Enviar formulario de registro
class RegistroSubmitEvent extends RegistroEvent {
  final String nombreCompleto;
  final String email;
  final String password;
  final String confirmPassword;

  const RegistroSubmitEvent({
    required this.nombreCompleto,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [nombreCompleto, email, password, confirmPassword];
}

/// Evento: Validar password mientras el usuario escribe
class ValidarPasswordEvent extends RegistroEvent {
  final String password;

  const ValidarPasswordEvent({required this.password});

  @override
  List<Object?> get props => [password];
}

/// Evento: Resetear estado del formulario
class RegistroResetEvent extends RegistroEvent {
  const RegistroResetEvent();
}
