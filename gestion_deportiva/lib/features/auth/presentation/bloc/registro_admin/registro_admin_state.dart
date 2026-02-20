import 'package:equatable/equatable.dart';

import '../../../data/models/registro_admin_response_model.dart';

/// E001-HU-001: Estados del Bloc de Registro de Administrador
abstract class RegistroAdminState extends Equatable {
  const RegistroAdminState();

  @override
  List<Object?> get props => [];
}

/// Estado: Inicial (formulario vacio)
class RegistroAdminInitial extends RegistroAdminState {
  const RegistroAdminInitial();
}

/// Estado: Cargando (procesando registro)
class RegistroAdminLoading extends RegistroAdminState {
  const RegistroAdminLoading();
}

/// Estado: Registro exitoso
/// CA-001: Cuenta creada con estado activo
/// CA-008: Redireccion post-registro
class RegistroAdminSuccess extends RegistroAdminState {
  final RegistroAdminResponseModel response;

  const RegistroAdminSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

/// Estado: Error en registro
class RegistroAdminError extends RegistroAdminState {
  final String message;
  final String? hint;

  const RegistroAdminError({
    required this.message,
    this.hint,
  });

  @override
  List<Object?> get props => [message, hint];
}

/// Estado: Validacion de password en tiempo real
/// CA-004: Requisitos de contrasena
class RegistroAdminPasswordValidation extends RegistroAdminState {
  final bool esValido;
  final List<String> errores;

  const RegistroAdminPasswordValidation({
    required this.esValido,
    required this.errores,
  });

  @override
  List<Object?> get props => [esValido, errores];
}

/// Estado: Error de validacion frontend
class RegistroAdminValidationError extends RegistroAdminState {
  final Map<String, String> errores;

  const RegistroAdminValidationError({required this.errores});

  @override
  List<Object?> get props => [errores];
}
