import 'package:equatable/equatable.dart';

/// Clase base para todos los Failures de la aplicacion
/// Usada en el patron Either para manejo de errores
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Failure para errores del servidor/backend
class ServerFailure extends Failure {
  final String? code;
  final String? hint;

  const ServerFailure({
    required super.message,
    this.code,
    this.hint,
  });

  @override
  List<Object?> get props => [message, code, hint];
}

/// Failure para errores de cache local
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Failure para errores de conexion de red
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// Failure para errores de validacion
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// Failure para errores de autenticacion
class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}
