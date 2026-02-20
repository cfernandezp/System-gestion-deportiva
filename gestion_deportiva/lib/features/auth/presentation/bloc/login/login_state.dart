import 'package:equatable/equatable.dart';

import '../../../data/models/login_response_model.dart';

/// E001-HU-002: Estados del Bloc de Login
abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

/// Estado: Inicial (formulario vacio)
class LoginInitial extends LoginState {
  const LoginInitial();
}

/// Estado: Cargando (procesando login)
class LoginLoading extends LoginState {
  const LoginLoading();
}

/// Estado: Login exitoso
/// CA-001: Un grupo -> home directo
/// CA-002: Multiples grupos -> seleccion (futuro)
/// CA-006: Sin grupos -> crear grupo (futuro)
class LoginSuccess extends LoginState {
  final LoginResponseModel response;

  const LoginSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

/// Tipos de error de login
enum LoginErrorType {
  /// RN-003: Credenciales invalidas (mensaje generico)
  credencialesInvalidas,

  /// CA-005 / RN-005: Cuenta pendiente de activacion (jugador invitado)
  cuentaPendienteActivacion,

  /// Cuenta pendiente de aprobacion (flujo legacy)
  cuentaPendiente,

  /// Cuenta rechazada
  cuentaRechazada,

  /// RN-002: Cuenta bloqueada por intentos fallidos
  cuentaBloqueada,

  /// Error de validacion de campos
  validacion,

  /// Error de conexion/servidor
  servidor,
}

/// Estado: Error en login
/// CA-003: Mensaje generico para credenciales incorrectas
class LoginError extends LoginState {
  final String message;
  final LoginErrorType errorType;
  final String? hint;
  final int? minutosRestantes;

  const LoginError({
    required this.message,
    required this.errorType,
    this.hint,
    this.minutosRestantes,
  });

  @override
  List<Object?> get props => [message, errorType, hint, minutosRestantes];
}

/// Estado: Error de validacion frontend
class LoginValidationError extends LoginState {
  final Map<String, String> errores;

  const LoginValidationError({required this.errores});

  @override
  List<Object?> get props => [errores];
}

/// Estado: Informacion de bloqueo
/// RN-002: Mostrar intentos restantes y tiempo de bloqueo
class LoginBloqueoInfo extends LoginState {
  final bool bloqueado;
  final int intentosRestantes;
  final int? minutosRestantes;

  const LoginBloqueoInfo({
    required this.bloqueado,
    required this.intentosRestantes,
    this.minutosRestantes,
  });

  @override
  List<Object?> get props => [bloqueado, intentosRestantes, minutosRestantes];
}
