import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

/// Bloc para manejar el inicio de sesion
/// Implementa HU-002: Inicio de Sesion
///
/// Criterios de Aceptacion:
/// - CA-001: Formulario con email y contrasena
/// - CA-002: Login exitoso -> navegar a home
/// - CA-003: Mostrar error generico si credenciales invalidas
/// - CA-004: Validar campos obligatorios
/// - CA-005: Link a registro
/// - CA-006: Link a recuperacion de contrasena
///
/// Reglas de Negocio:
/// - RN-001: Campos email y contrasena obligatorios
/// - RN-002: Mostrar mensaje diferenciado si cuenta pendiente/rechazada
/// - RN-004: Mensaje generico para credenciales invalidas
/// - RN-007: Mostrar mensaje de bloqueo con minutos restantes
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository repository;

  LoginBloc({required this.repository}) : super(const LoginInitial()) {
    on<LoginSubmitEvent>(_onLoginSubmit);
    on<LoginResetEvent>(_onLoginReset);
    on<VerificarBloqueoEvent>(_onVerificarBloqueo);
  }

  /// Maneja el envio del formulario de login
  /// CA-002, CA-003, CA-004
  Future<void> _onLoginSubmit(
    LoginSubmitEvent event,
    Emitter<LoginState> emit,
  ) async {
    // CA-004, RN-001: Validaciones frontend primero
    final erroresValidacion = _validarFormulario(
      email: event.email,
      password: event.password,
    );

    if (erroresValidacion.isNotEmpty) {
      emit(LoginValidationError(errores: erroresValidacion));
      return;
    }

    emit(const LoginLoading());

    // Llamar al backend
    final result = await repository.iniciarSesion(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) {
        // Mapear hints a tipos de error y mensajes amigables
        final errorInfo = _mapearErrorBackend(failure);
        emit(LoginError(
          message: errorInfo.message,
          errorType: errorInfo.errorType,
          hint: errorInfo.hint,
          minutosRestantes: errorInfo.minutosRestantes,
        ));
      },
      (response) => emit(LoginSuccess(response: response)),
    );
  }

  /// Resetea el estado del formulario
  void _onLoginReset(
    LoginResetEvent event,
    Emitter<LoginState> emit,
  ) {
    emit(const LoginInitial());
  }

  /// Verifica el estado de bloqueo de un email
  /// RN-007: Proteccion contra fuerza bruta
  Future<void> _onVerificarBloqueo(
    VerificarBloqueoEvent event,
    Emitter<LoginState> emit,
  ) async {
    if (event.email.isEmpty) return;

    final result = await repository.verificarBloqueoLogin(email: event.email);

    result.fold(
      (failure) {
        // Si falla la verificacion, no mostramos error, solo continuamos
      },
      (bloqueoInfo) {
        if (bloqueoInfo.bloqueado) {
          emit(LoginBloqueoInfo(
            bloqueado: true,
            intentosRestantes: 0,
            minutosRestantes: bloqueoInfo.minutosRestantes,
          ));
        } else if (bloqueoInfo.intentosFallidos > 0) {
          emit(LoginBloqueoInfo(
            bloqueado: false,
            intentosRestantes: bloqueoInfo.intentosRestantes,
          ));
        }
      },
    );
  }

  /// Validaciones frontend del formulario
  /// RN-001: Campos obligatorios
  Map<String, String> _validarFormulario({
    required String email,
    required String password,
  }) {
    final errores = <String, String>{};

    // RN-001: Email obligatorio
    if (email.trim().isEmpty) {
      errores['email'] = 'El email es obligatorio';
    } else if (!_esEmailValido(email)) {
      errores['email'] = 'Ingresa un email valido';
    }

    // RN-001: Password obligatorio
    if (password.isEmpty) {
      errores['password'] = 'La contrasena es obligatoria';
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

  /// Mapea hints del backend a tipos de error y mensajes amigables
  /// RN-002: cuenta_pendiente, cuenta_rechazada
  /// RN-004: credenciales_invalidas
  /// RN-007: cuenta_bloqueada
  _LoginErrorInfo _mapearErrorBackend(Failure failure) {
    String mensaje = failure.message;
    LoginErrorType errorType = LoginErrorType.servidor;
    String? hint;
    int? minutosRestantes;

    if (failure is ServerFailure) {
      hint = failure.hint;

      switch (failure.hint) {
        case 'credenciales_invalidas':
          // RN-004: Mensaje generico por seguridad
          mensaje = 'Email o contrasena incorrectos';
          errorType = LoginErrorType.credencialesInvalidas;
          break;

        case 'cuenta_pendiente':
          // RN-002: Cuenta pendiente de aprobacion
          mensaje =
              'Tu cuenta esta pendiente de aprobacion. Un administrador revisara tu solicitud.';
          errorType = LoginErrorType.cuentaPendiente;
          break;

        case 'cuenta_rechazada':
          // RN-002: Cuenta rechazada
          mensaje =
              'Tu solicitud de registro fue rechazada. Contacta al administrador para mas informacion.';
          errorType = LoginErrorType.cuentaRechazada;
          break;

        case 'cuenta_bloqueada':
          // RN-007: Cuenta bloqueada por intentos fallidos
          // Extraer minutos restantes del mensaje si esta disponible
          final regExp = RegExp(r'(\d+)\s*minuto');
          final match = regExp.firstMatch(failure.message);
          if (match != null) {
            minutosRestantes = int.tryParse(match.group(1) ?? '');
          }
          mensaje = minutosRestantes != null
              ? 'Cuenta bloqueada temporalmente. Intenta nuevamente en $minutosRestantes minutos.'
              : 'Cuenta bloqueada temporalmente por demasiados intentos fallidos.';
          errorType = LoginErrorType.cuentaBloqueada;
          break;

        case 'campo_requerido':
          mensaje = 'Por favor completa todos los campos';
          errorType = LoginErrorType.validacion;
          break;

        default:
          // Error generico del servidor
          mensaje = failure.message;
          errorType = LoginErrorType.servidor;
      }
    }

    return _LoginErrorInfo(
      message: mensaje,
      errorType: errorType,
      hint: hint,
      minutosRestantes: minutosRestantes,
    );
  }
}

/// Clase auxiliar para mapeo de errores
class _LoginErrorInfo {
  final String message;
  final LoginErrorType errorType;
  final String? hint;
  final int? minutosRestantes;

  _LoginErrorInfo({
    required this.message,
    required this.errorType,
    this.hint,
    this.minutosRestantes,
  });
}
