import 'package:equatable/equatable.dart';

import '../../../data/models/registro_response_model.dart';

/// Estados del Bloc de Registro
abstract class RegistroState extends Equatable {
  const RegistroState();

  @override
  List<Object?> get props => [];
}

/// Estado: Inicial (formulario vacio)
class RegistroInitial extends RegistroState {
  const RegistroInitial();
}

/// Estado: Cargando (procesando registro)
class RegistroLoading extends RegistroState {
  const RegistroLoading();
}

/// Estado: Registro exitoso
class RegistroSuccess extends RegistroState {
  final RegistroResponseModel response;

  const RegistroSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

/// Estado: Error en registro
class RegistroError extends RegistroState {
  final String message;
  final String? hint;

  const RegistroError({
    required this.message,
    this.hint,
  });

  @override
  List<Object?> get props => [message, hint];
}

/// Estado: Validacion de password
class RegistroPasswordValidation extends RegistroState {
  final bool esValido;
  final List<String> errores;

  const RegistroPasswordValidation({
    required this.esValido,
    required this.errores,
  });

  @override
  List<Object?> get props => [esValido, errores];
}

/// Estado: Error de validacion frontend
class RegistroValidationError extends RegistroState {
  final Map<String, String> errores;

  const RegistroValidationError({required this.errores});

  @override
  List<Object?> get props => [errores];
}
