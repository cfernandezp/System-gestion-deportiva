import 'package:equatable/equatable.dart';

/// Estados del Bloc de Recuperacion de Contrasena
/// HU-003: Recuperacion de Contrasena
abstract class RecuperacionState extends Equatable {
  const RecuperacionState();

  @override
  List<Object?> get props => [];
}

/// Estado: Inicial (formulario vacio)
class RecuperacionInitial extends RecuperacionState {
  const RecuperacionInitial();
}

/// Estado: Cargando (procesando solicitud)
class RecuperacionLoading extends RecuperacionState {
  const RecuperacionLoading();
}

/// Estado: Email de recuperacion enviado
/// CA-002: Email enviado con instrucciones
/// RN-001: Mensaje generico por seguridad
class RecuperacionEmailEnviado extends RecuperacionState {
  final String mensaje;
  final String? token; // Token para desarrollo/testing (no mostrar en produccion)

  const RecuperacionEmailEnviado({
    required this.mensaje,
    this.token,
  });

  @override
  List<Object?> get props => [mensaje, token];
}

/// Estado: Token valido, mostrar formulario de nueva contrasena
/// CA-004: Enlace valido
class RecuperacionTokenValido extends RecuperacionState {
  final String email;
  final String? nombre;
  final int? minutosRestantes;

  const RecuperacionTokenValido({
    required this.email,
    this.nombre,
    this.minutosRestantes,
  });

  @override
  List<Object?> get props => [email, nombre, minutosRestantes];
}

/// Tipos de error de token
enum TokenErrorType {
  /// Token no proporcionado
  tokenRequerido,

  /// Token no existe
  tokenInvalido,

  /// Token ya fue usado
  tokenUsado,

  /// Token expiro (RN-002)
  tokenExpirado,
}

/// Estado: Token invalido
/// CA-005: Enlace expirado o invalido
class RecuperacionTokenInvalido extends RecuperacionState {
  final String mensaje;
  final TokenErrorType errorType;

  const RecuperacionTokenInvalido({
    required this.mensaje,
    required this.errorType,
  });

  @override
  List<Object?> get props => [mensaje, errorType];
}

/// Estado: Contrasena actualizada exitosamente
/// CA-006: Nueva contrasena establecida
/// RN-006: Sesiones cerradas
class RecuperacionContrasenaActualizada extends RecuperacionState {
  final String email;
  final String mensaje;
  final bool sesionesCerradas;

  const RecuperacionContrasenaActualizada({
    required this.email,
    required this.mensaje,
    required this.sesionesCerradas,
  });

  @override
  List<Object?> get props => [email, mensaje, sesionesCerradas];
}

/// Tipos de error de recuperacion
enum RecuperacionErrorType {
  /// Error de validacion frontend
  validacion,

  /// Error de conexion
  conexion,

  /// Contrasenas no coinciden (RN-005)
  contrasenasNoCoinciden,

  /// Contrasena no cumple requisitos (RN-004)
  contrasenaInvalida,

  /// Contrasena igual a anterior (RN-004)
  contrasenaIgualAnterior,

  /// Error generico del servidor
  servidor,
}

/// Estado: Error en recuperacion
class RecuperacionError extends RecuperacionState {
  final String mensaje;
  final RecuperacionErrorType errorType;
  final String? hint;

  const RecuperacionError({
    required this.mensaje,
    required this.errorType,
    this.hint,
  });

  @override
  List<Object?> get props => [mensaje, errorType, hint];
}

/// Estado: Error de validacion frontend
class RecuperacionValidationError extends RecuperacionState {
  final Map<String, String> errores;

  const RecuperacionValidationError({required this.errores});

  @override
  List<Object?> get props => [errores];
}
