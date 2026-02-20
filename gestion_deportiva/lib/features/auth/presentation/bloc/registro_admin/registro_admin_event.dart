import 'package:equatable/equatable.dart';

/// E001-HU-001: Eventos del Bloc de Registro de Administrador
abstract class RegistroAdminEvent extends Equatable {
  const RegistroAdminEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Enviar formulario de registro de admin
/// CA-001: Registro con celular, nombre, contrasena, pregunta seguridad
/// CA-006: Pregunta de seguridad obligatoria
/// CA-007: Email de respaldo opcional
class RegistroAdminSubmitEvent extends RegistroAdminEvent {
  final String celular;
  final String nombreCompleto;
  final String password;
  final String confirmPassword;
  final String preguntaSeguridad;
  final String respuestaSeguridad;
  final String? emailRespaldo;

  const RegistroAdminSubmitEvent({
    required this.celular,
    required this.nombreCompleto,
    required this.password,
    required this.confirmPassword,
    required this.preguntaSeguridad,
    required this.respuestaSeguridad,
    this.emailRespaldo,
  });

  @override
  List<Object?> get props => [
        celular,
        nombreCompleto,
        password,
        confirmPassword,
        preguntaSeguridad,
        respuestaSeguridad,
        emailRespaldo,
      ];
}

/// Evento: Validar password mientras el usuario escribe
/// CA-004: Validacion de contrasena segura
class ValidarPasswordAdminEvent extends RegistroAdminEvent {
  final String password;

  const ValidarPasswordAdminEvent({required this.password});

  @override
  List<Object?> get props => [password];
}

/// Evento: Resetear estado del formulario
class RegistroAdminResetEvent extends RegistroAdminEvent {
  const RegistroAdminResetEvent();
}
