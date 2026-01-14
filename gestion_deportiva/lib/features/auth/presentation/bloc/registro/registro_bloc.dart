import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'registro_event.dart';
import 'registro_state.dart';

/// Bloc para manejar el registro de usuarios
/// Implementa validaciones frontend y llama al backend
class RegistroBloc extends Bloc<RegistroEvent, RegistroState> {
  final AuthRepository repository;

  RegistroBloc({required this.repository}) : super(const RegistroInitial()) {
    on<RegistroSubmitEvent>(_onRegistroSubmit);
    on<ValidarPasswordEvent>(_onValidarPassword);
    on<RegistroResetEvent>(_onRegistroReset);
  }

  /// Maneja el envio del formulario de registro
  Future<void> _onRegistroSubmit(
    RegistroSubmitEvent event,
    Emitter<RegistroState> emit,
  ) async {
    // Validaciones frontend primero
    final erroresValidacion = _validarFormulario(
      nombreCompleto: event.nombreCompleto,
      email: event.email,
      password: event.password,
      confirmPassword: event.confirmPassword,
    );

    if (erroresValidacion.isNotEmpty) {
      emit(RegistroValidationError(errores: erroresValidacion));
      return;
    }

    emit(const RegistroLoading());

    // Llamar al backend
    final result = await repository.registrarUsuario(
      nombreCompleto: event.nombreCompleto,
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) {
        // Mapear hints a mensajes amigables
        String mensaje = failure.message;
        String? hint;

        if (failure is ServerFailure) {
          hint = failure.hint;
          mensaje = _mapearErrorBackend(failure.hint ?? '', failure.message);
        }

        emit(RegistroError(message: mensaje, hint: hint));
      },
      (response) => emit(RegistroSuccess(response: response)),
    );
  }

  /// Maneja la validacion de password en tiempo real
  Future<void> _onValidarPassword(
    ValidarPasswordEvent event,
    Emitter<RegistroState> emit,
  ) async {
    if (event.password.isEmpty) {
      emit(const RegistroPasswordValidation(esValido: true, errores: []));
      return;
    }

    final result = await repository.validarPassword(password: event.password);

    result.fold(
      (failure) => emit(RegistroError(message: failure.message)),
      (validacion) => emit(RegistroPasswordValidation(
        esValido: validacion.esValido,
        errores: validacion.errores,
      )),
    );
  }

  /// Resetea el estado del formulario
  void _onRegistroReset(
    RegistroResetEvent event,
    Emitter<RegistroState> emit,
  ) {
    emit(const RegistroInitial());
  }

  /// Validaciones frontend del formulario
  /// RN-003: Coincidencia de contrasenas (frontend)
  /// RN-009: Datos obligatorios
  /// RN-010: Formato email valido
  Map<String, String> _validarFormulario({
    required String nombreCompleto,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final errores = <String, String>{};

    // RN-009: Nombre minimo 2 caracteres
    if (nombreCompleto.trim().isEmpty) {
      errores['nombreCompleto'] = 'El nombre es obligatorio';
    } else if (nombreCompleto.trim().length < 2) {
      errores['nombreCompleto'] = 'El nombre debe tener al menos 2 caracteres';
    }

    // RN-009 y RN-010: Email obligatorio y formato valido
    if (email.trim().isEmpty) {
      errores['email'] = 'El email es obligatorio';
    } else if (!_esEmailValido(email)) {
      errores['email'] = 'Ingresa un email valido';
    }

    // RN-009: Password obligatorio
    if (password.isEmpty) {
      errores['password'] = 'La contrasena es obligatoria';
    }

    // RN-003: Confirmacion de password
    if (confirmPassword.isEmpty) {
      errores['confirmPassword'] = 'Confirma tu contrasena';
    } else if (password != confirmPassword) {
      errores['confirmPassword'] = 'Las contrasenas no coinciden';
    }

    return errores;
  }

  /// Valida formato de email (RN-010)
  bool _esEmailValido(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email.trim());
  }

  /// Mapea hints del backend a mensajes amigables
  /// CA-002: email_duplicado
  /// CA-003: password_invalido
  String _mapearErrorBackend(String hint, String mensajeDefault) {
    switch (hint) {
      case 'email_duplicado':
        return 'Este email ya esta registrado. Intenta con otro email o inicia sesion.';
      case 'email_formato_invalido':
        return 'El formato del email no es valido.';
      case 'nombre_invalido':
        return 'El nombre debe tener al menos 2 caracteres.';
      case 'password_invalido':
        return 'La contrasena no cumple los requisitos de seguridad.';
      default:
        return mensajeDefault;
    }
  }
}
