import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

/// E001-HU-002: Bloc para manejar el inicio de sesion
///
/// Criterios de Aceptacion:
/// - CA-001: Login exitoso con un solo grupo -> home directo
/// - CA-002: Login exitoso con multiples grupos -> seleccion de grupo
/// - CA-003: Credenciales incorrectas -> mensaje generico
/// - CA-004: Proteccion contra intentos repetidos (bloqueo temporal)
/// - CA-005: Cuenta pendiente de activacion -> informar
/// - CA-006: Sin grupos -> crear grupo
///
/// Reglas de Negocio:
/// - RN-001: Autenticacion por celular y contrasena
/// - RN-002: Bloqueo temporal tras 5 intentos fallidos (15 min)
/// - RN-003: Mensaje generico para credenciales invalidas
/// - RN-004: Navegacion post-login segun cantidad de grupos
/// - RN-005: Restriccion login para cuentas pendientes de activacion
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository repository;

  LoginBloc({required this.repository}) : super(const LoginInitial()) {
    on<LoginSubmitEvent>(_onLoginSubmit);
    on<LoginResetEvent>(_onLoginReset);
    on<VerificarBloqueoEvent>(_onVerificarBloqueo);
  }

  /// Convierte celular a email derivado para Supabase Auth
  /// Misma convencion que E001-HU-001 (registro)
  String _celularAEmailDerivado(String celular) {
    final celularLimpio = celular.replaceAll(RegExp(r'[^0-9]'), '');
    return '$celularLimpio@gestiondeportiva.app';
  }

  /// Maneja el envio del formulario de login
  /// CA-001 a CA-006
  Future<void> _onLoginSubmit(
    LoginSubmitEvent event,
    Emitter<LoginState> emit,
  ) async {
    // RN-001: Validaciones frontend primero
    final erroresValidacion = _validarFormulario(
      celular: event.celular,
      password: event.password,
    );

    if (erroresValidacion.isNotEmpty) {
      emit(LoginValidationError(errores: erroresValidacion));
      return;
    }

    emit(const LoginLoading());

    // Convertir celular a email derivado para backend
    final emailDerivado = _celularAEmailDerivado(event.celular);

    // Llamar al backend con email derivado
    final result = await repository.iniciarSesion(
      email: emailDerivado,
      password: event.password,
    );

    result.fold(
      (failure) {
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

  /// Verifica el estado de bloqueo de un celular
  /// RN-002: Proteccion contra fuerza bruta
  Future<void> _onVerificarBloqueo(
    VerificarBloqueoEvent event,
    Emitter<LoginState> emit,
  ) async {
    if (event.celular.isEmpty) return;

    final emailDerivado = _celularAEmailDerivado(event.celular);
    final result = await repository.verificarBloqueoLogin(email: emailDerivado);

    result.fold(
      (failure) {
        // Si falla la verificacion, no mostramos error
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
  /// RN-001: Celular y contrasena obligatorios
  Map<String, String> _validarFormulario({
    required String celular,
    required String password,
  }) {
    final errores = <String, String>{};

    // RN-001: Celular obligatorio con formato Peru
    final celularLimpio = celular.replaceAll(RegExp(r'[^0-9]'), '');
    if (celularLimpio.isEmpty) {
      errores['celular'] = 'El numero de celular es obligatorio';
    } else if (celularLimpio.length != 9) {
      errores['celular'] = 'El celular debe tener 9 digitos';
    } else if (!celularLimpio.startsWith('9')) {
      errores['celular'] = 'El celular debe iniciar con 9';
    }

    // RN-001: Password obligatorio
    if (password.isEmpty) {
      errores['password'] = 'La contrasena es obligatoria';
    }

    return errores;
  }

  /// Mapea hints del backend a tipos de error y mensajes amigables
  /// RN-003: Mensaje generico para credenciales invalidas
  /// RN-005: Cuenta pendiente de activacion
  _LoginErrorInfo _mapearErrorBackend(Failure failure) {
    String mensaje = failure.message;
    LoginErrorType errorType = LoginErrorType.servidor;
    String? hint;
    int? minutosRestantes;

    if (failure is ServerFailure) {
      hint = failure.hint;

      switch (failure.hint) {
        case 'credenciales_invalidas':
          // RN-003: Mensaje generico por seguridad
          mensaje = 'Credenciales incorrectas';
          errorType = LoginErrorType.credencialesInvalidas;
          break;

        case 'usuario_pendiente':
        case 'cuenta_pendiente':
          // RN-005 / CA-005: Cuenta pendiente de activacion
          mensaje =
              'Tu cuenta esta pendiente de activacion. Completa el proceso de activacion para poder acceder.';
          errorType = LoginErrorType.cuentaPendienteActivacion;
          break;

        case 'usuario_rechazado':
        case 'cuenta_rechazada':
          mensaje =
              'Tu cuenta no tiene acceso al sistema. Contacta al administrador.';
          errorType = LoginErrorType.cuentaRechazada;
          break;

        case 'usuario_inactivo':
          mensaje =
              'Tu cuenta ha sido desactivada. Contacta al administrador.';
          errorType = LoginErrorType.cuentaRechazada;
          break;

        case 'cuenta_bloqueada':
          // RN-002: Cuenta bloqueada por intentos fallidos
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
