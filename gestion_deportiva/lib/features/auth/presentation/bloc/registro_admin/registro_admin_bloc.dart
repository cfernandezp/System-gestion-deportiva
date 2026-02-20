import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'registro_admin_event.dart';
import 'registro_admin_state.dart';

/// E001-HU-001: Bloc para manejar el registro de administrador
/// Implementa validaciones frontend y llama al backend
class RegistroAdminBloc extends Bloc<RegistroAdminEvent, RegistroAdminState> {
  final AuthRepository repository;

  RegistroAdminBloc({required this.repository})
      : super(const RegistroAdminInitial()) {
    on<RegistroAdminSubmitEvent>(_onRegistroSubmit);
    on<ValidarPasswordAdminEvent>(_onValidarPassword);
    on<RegistroAdminResetEvent>(_onRegistroReset);
  }

  /// Maneja el envio del formulario de registro de admin
  Future<void> _onRegistroSubmit(
    RegistroAdminSubmitEvent event,
    Emitter<RegistroAdminState> emit,
  ) async {
    // Validaciones frontend primero
    final erroresValidacion = _validarFormulario(
      celular: event.celular,
      nombreCompleto: event.nombreCompleto,
      password: event.password,
      confirmPassword: event.confirmPassword,
      preguntaSeguridad: event.preguntaSeguridad,
      respuestaSeguridad: event.respuestaSeguridad,
      emailRespaldo: event.emailRespaldo,
    );

    if (erroresValidacion.isNotEmpty) {
      emit(RegistroAdminValidationError(errores: erroresValidacion));
      return;
    }

    emit(const RegistroAdminLoading());

    // Llamar al backend
    final result = await repository.registrarAdministrador(
      celular: event.celular.trim(),
      nombreCompleto: event.nombreCompleto.trim(),
      password: event.password,
      preguntaSeguridad: event.preguntaSeguridad,
      respuestaSeguridad: event.respuestaSeguridad.trim(),
      emailRespaldo: event.emailRespaldo?.trim(),
    );

    result.fold(
      (failure) {
        String mensaje = failure.message;
        String? hint;

        if (failure is ServerFailure) {
          hint = failure.hint;
          mensaje = _mapearErrorBackend(failure.hint ?? '', failure.message);
        }

        emit(RegistroAdminError(message: mensaje, hint: hint));
      },
      (response) => emit(RegistroAdminSuccess(response: response)),
    );
  }

  /// Maneja la validacion de password en tiempo real
  /// CA-004: Validacion de contrasena segura
  Future<void> _onValidarPassword(
    ValidarPasswordAdminEvent event,
    Emitter<RegistroAdminState> emit,
  ) async {
    if (event.password.isEmpty) {
      emit(const RegistroAdminPasswordValidation(esValido: true, errores: []));
      return;
    }

    final result = await repository.validarPassword(password: event.password);

    result.fold(
      (failure) => emit(RegistroAdminError(message: failure.message)),
      (validacion) => emit(RegistroAdminPasswordValidation(
        esValido: validacion.esValido,
        errores: validacion.errores,
      )),
    );
  }

  /// Resetea el estado del formulario
  void _onRegistroReset(
    RegistroAdminResetEvent event,
    Emitter<RegistroAdminState> emit,
  ) {
    emit(const RegistroAdminInitial());
  }

  /// Validaciones frontend del formulario
  /// RN-002: Formato celular Peru (9 digitos, inicia con 9)
  /// RN-003: Requisitos de contrasena
  /// RN-004: Pregunta de seguridad obligatoria
  /// RN-005: Email de respaldo opcional con formato valido
  Map<String, String> _validarFormulario({
    required String celular,
    required String nombreCompleto,
    required String password,
    required String confirmPassword,
    required String preguntaSeguridad,
    required String respuestaSeguridad,
    String? emailRespaldo,
  }) {
    final errores = <String, String>{};

    // CA-005: Nombre obligatorio, minimo 2 caracteres
    if (nombreCompleto.trim().isEmpty) {
      errores['nombreCompleto'] = 'El nombre es obligatorio';
    } else if (nombreCompleto.trim().length < 2) {
      errores['nombreCompleto'] = 'El nombre debe tener al menos 2 caracteres';
    }

    // CA-003 / RN-002: Celular obligatorio, formato Peru
    final celularLimpio = celular.replaceAll(RegExp(r'[^0-9]'), '');
    if (celularLimpio.isEmpty) {
      errores['celular'] = 'El numero de celular es obligatorio';
    } else if (celularLimpio.length != 9) {
      errores['celular'] = 'El celular debe tener exactamente 9 digitos';
    } else if (!celularLimpio.startsWith('9')) {
      errores['celular'] = 'El celular debe iniciar con el digito 9';
    }

    // Password obligatorio
    if (password.isEmpty) {
      errores['password'] = 'La contrasena es obligatoria';
    }

    // RN-003: Confirmacion de password
    if (confirmPassword.isEmpty) {
      errores['confirmPassword'] = 'Confirma tu contrasena';
    } else if (password != confirmPassword) {
      errores['confirmPassword'] = 'Las contrasenas no coinciden';
    }

    // CA-006 / RN-004: Pregunta de seguridad obligatoria
    if (preguntaSeguridad.trim().isEmpty) {
      errores['preguntaSeguridad'] = 'Selecciona una pregunta de seguridad';
    }

    // CA-006 / RN-004: Respuesta de seguridad obligatoria
    if (respuestaSeguridad.trim().isEmpty) {
      errores['respuestaSeguridad'] =
          'La respuesta a la pregunta de seguridad es obligatoria';
    }

    // CA-007 / RN-005: Email de respaldo opcional pero con formato valido
    if (emailRespaldo != null && emailRespaldo.trim().isNotEmpty) {
      if (!_esEmailValido(emailRespaldo)) {
        errores['emailRespaldo'] = 'Ingresa un email valido';
      }
    }

    return errores;
  }

  /// Valida formato de email
  bool _esEmailValido(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email.trim());
  }

  /// Mapea hints del backend a mensajes amigables
  /// CA-002: celular_duplicado
  /// CA-003: celular_formato_invalido
  /// CA-004: password_invalido
  String _mapearErrorBackend(String hint, String mensajeDefault) {
    switch (hint) {
      case 'celular_duplicado':
        return 'Este numero de celular ya esta registrado. Intenta iniciar sesion o recuperar tu contrasena.';
      case 'celular_formato_invalido':
        return 'El formato del celular no es valido. Debe tener 9 digitos e iniciar con 9.';
      case 'nombre_invalido':
        return 'El nombre debe tener al menos 2 caracteres.';
      case 'password_invalido':
        return 'La contrasena no cumple los requisitos de seguridad.';
      case 'pregunta_seguridad_requerida':
        return 'Debes seleccionar una pregunta de seguridad.';
      case 'respuesta_seguridad_requerida':
        return 'Debes proporcionar una respuesta a la pregunta de seguridad.';
      case 'email_formato_invalido':
        return 'El formato del email de respaldo no es valido.';
      default:
        return mensajeDefault;
    }
  }
}
