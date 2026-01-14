import 'package:equatable/equatable.dart';

import '../../../data/models/login_response_model.dart';

/// Estados del Bloc de Login
/// HU-002: Inicio de Sesion
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
/// CA-002: Navegar a home
class LoginSuccess extends LoginState {
  final LoginResponseModel response;

  const LoginSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

/// Tipos de error de login para RN-002, RN-004, RN-007
enum LoginErrorType {
  /// RN-004: Credenciales invalidas (mensaje generico)
  credencialesInvalidas,

  /// RN-002: Cuenta pendiente de aprobacion
  cuentaPendiente,

  /// RN-002: Cuenta rechazada
  cuentaRechazada,

  /// RN-007: Cuenta bloqueada por intentos fallidos
  cuentaBloqueada,

  /// Error de validacion de campos
  validacion,

  /// Error de conexion/servidor
  servidor,
}

/// Estado: Error en login
/// CA-003: Mostrar mensaje de error apropiado
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
/// CA-004: Campos obligatorios
class LoginValidationError extends LoginState {
  final Map<String, String> errores;

  const LoginValidationError({required this.errores});

  @override
  List<Object?> get props => [errores];
}

/// Estado: Informacion de bloqueo
/// RN-007: Mostrar intentos restantes
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
