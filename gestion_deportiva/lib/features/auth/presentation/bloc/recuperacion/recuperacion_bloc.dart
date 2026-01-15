import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'recuperacion_event.dart';
import 'recuperacion_state.dart';

/// Bloc para manejar la recuperacion de contrasena
/// Implementa HU-003: Recuperacion de Contrasena
///
/// Criterios de Aceptacion:
/// - CA-001: Formulario con campo email
/// - CA-002: Email de recuperacion enviado
/// - CA-003: Mensaje uniforme (email exista o no)
/// - CA-004: Validar enlace de recuperacion
/// - CA-005: Mensaje de enlace expirado
/// - CA-006: Establecer nueva contrasena
///
/// Reglas de Negocio:
/// - RN-001: Mensaje uniforme (no revelar si email existe)
/// - RN-002: Enlace valido por 1 hora
/// - RN-003: Uso unico del enlace
/// - RN-004: Requisitos de nueva contrasena + diferente a anterior
/// - RN-005: Confirmacion debe coincidir
/// - RN-006: Cerrar sesiones al cambiar contrasena
class RecuperacionBloc extends Bloc<RecuperacionEvent, RecuperacionState> {
  final AuthRepository repository;

  RecuperacionBloc({required this.repository})
      : super(const RecuperacionInitial()) {
    on<SolicitarRecuperacionEvent>(_onSolicitarRecuperacion);
    on<ValidarTokenEvent>(_onValidarToken);
    on<RestablecerContrasenaEvent>(_onRestablecerContrasena);
    on<RecuperacionResetEvent>(_onReset);
  }

  /// Maneja solicitud de recuperacion de contrasena
  /// CA-001, CA-002, CA-003, RN-001
  Future<void> _onSolicitarRecuperacion(
    SolicitarRecuperacionEvent event,
    Emitter<RecuperacionState> emit,
  ) async {
    // Validacion frontend
    final errores = _validarEmail(event.email);
    if (errores.isNotEmpty) {
      emit(RecuperacionValidationError(errores: errores));
      return;
    }

    emit(const RecuperacionLoading());

    final result = await repository.solicitarRecuperacion(email: event.email);

    result.fold(
      (failure) {
        final errorInfo = _mapearErrorBackend(failure);
        emit(RecuperacionError(
          mensaje: errorInfo.mensaje,
          errorType: errorInfo.errorType,
          hint: errorInfo.hint,
        ));
      },
      (response) {
        // RN-001: Siempre mostramos mensaje generico
        emit(RecuperacionEmailEnviado(
          mensaje: response.mensaje,
          token: response.token, // Para desarrollo/testing
        ));
      },
    );
  }

  /// Maneja validacion de token de recuperacion
  /// CA-004, CA-005
  Future<void> _onValidarToken(
    ValidarTokenEvent event,
    Emitter<RecuperacionState> emit,
  ) async {
    if (event.token.isEmpty) {
      emit(const RecuperacionTokenInvalido(
        mensaje: 'Token de recuperacion no proporcionado',
        errorType: TokenErrorType.tokenRequerido,
      ));
      return;
    }

    emit(const RecuperacionLoading());

    final result = await repository.validarTokenRecuperacion(token: event.token);

    result.fold(
      (failure) {
        final tokenError = _mapearErrorToken(failure);
        emit(RecuperacionTokenInvalido(
          mensaje: tokenError.mensaje,
          errorType: tokenError.errorType,
        ));
      },
      (response) {
        if (response.valido) {
          emit(RecuperacionTokenValido(
            email: response.email ?? '',
            nombre: response.nombre,
            minutosRestantes: response.minutosRestantes,
          ));
        } else {
          emit(const RecuperacionTokenInvalido(
            mensaje: 'El enlace de recuperacion no es valido',
            errorType: TokenErrorType.tokenInvalido,
          ));
        }
      },
    );
  }

  /// Maneja restablecimiento de contrasena
  /// CA-006, RN-004, RN-005, RN-006
  Future<void> _onRestablecerContrasena(
    RestablecerContrasenaEvent event,
    Emitter<RecuperacionState> emit,
  ) async {
    // Validacion frontend
    final errores = _validarContrasenas(
      event.nuevaContrasena,
      event.confirmarContrasena,
    );
    if (errores.isNotEmpty) {
      emit(RecuperacionValidationError(errores: errores));
      return;
    }

    emit(const RecuperacionLoading());

    final result = await repository.restablecerContrasena(
      token: event.token,
      nuevaContrasena: event.nuevaContrasena,
      confirmarContrasena: event.confirmarContrasena,
    );

    result.fold(
      (failure) {
        // Verificar si es error de token
        if (failure is ServerFailure) {
          final hint = failure.hint;
          if (hint == 'token_invalido' ||
              hint == 'token_usado' ||
              hint == 'token_expirado') {
            final tokenError = _mapearErrorToken(failure);
            emit(RecuperacionTokenInvalido(
              mensaje: tokenError.mensaje,
              errorType: tokenError.errorType,
            ));
            return;
          }
        }

        final errorInfo = _mapearErrorRestablecimiento(failure);
        emit(RecuperacionError(
          mensaje: errorInfo.mensaje,
          errorType: errorInfo.errorType,
          hint: errorInfo.hint,
        ));
      },
      (response) {
        emit(RecuperacionContrasenaActualizada(
          email: response.email,
          mensaje: response.mensaje,
          sesionesCerradas: response.sesionesCerradas,
        ));
      },
    );
  }

  /// Resetea el estado del bloc
  void _onReset(
    RecuperacionResetEvent event,
    Emitter<RecuperacionState> emit,
  ) {
    emit(const RecuperacionInitial());
  }

  /// Validacion frontend del email
  Map<String, String> _validarEmail(String email) {
    final errores = <String, String>{};

    if (email.trim().isEmpty) {
      errores['email'] = 'El email es obligatorio';
    } else if (!_esEmailValido(email)) {
      errores['email'] = 'Ingresa un email valido';
    }

    return errores;
  }

  /// Validacion frontend de contrasenas
  /// RN-005: Confirmacion debe coincidir
  Map<String, String> _validarContrasenas(
    String nueva,
    String confirmar,
  ) {
    final errores = <String, String>{};

    if (nueva.isEmpty) {
      errores['nuevaContrasena'] = 'La contrasena es obligatoria';
    } else if (nueva.length < 8) {
      errores['nuevaContrasena'] = 'Minimo 8 caracteres';
    }

    if (confirmar.isEmpty) {
      errores['confirmarContrasena'] = 'Confirma tu contrasena';
    } else if (nueva != confirmar) {
      errores['confirmarContrasena'] = 'Las contrasenas no coinciden';
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

  /// Mapea errores de token del backend
  _TokenErrorInfo _mapearErrorToken(Failure failure) {
    String mensaje = failure.message;
    TokenErrorType errorType = TokenErrorType.tokenInvalido;

    if (failure is ServerFailure) {
      switch (failure.hint) {
        case 'token_requerido':
          mensaje = 'Token de recuperacion no proporcionado';
          errorType = TokenErrorType.tokenRequerido;
          break;
        case 'token_invalido':
          mensaje = 'El enlace de recuperacion no es valido';
          errorType = TokenErrorType.tokenInvalido;
          break;
        case 'token_usado':
          mensaje = 'Este enlace ya fue utilizado. Solicita uno nuevo.';
          errorType = TokenErrorType.tokenUsado;
          break;
        case 'token_expirado':
          mensaje = 'El enlace ha expirado. Solicita uno nuevo.';
          errorType = TokenErrorType.tokenExpirado;
          break;
        default:
          mensaje = failure.message;
          errorType = TokenErrorType.tokenInvalido;
      }
    }

    return _TokenErrorInfo(mensaje: mensaje, errorType: errorType);
  }

  /// Mapea errores generales del backend
  _ErrorInfo _mapearErrorBackend(Failure failure) {
    return _ErrorInfo(
      mensaje: failure.message,
      errorType: RecuperacionErrorType.servidor,
      hint: failure is ServerFailure ? failure.hint : null,
    );
  }

  /// Mapea errores de restablecimiento del backend
  _ErrorInfo _mapearErrorRestablecimiento(Failure failure) {
    String mensaje = failure.message;
    RecuperacionErrorType errorType = RecuperacionErrorType.servidor;
    String? hint;

    if (failure is ServerFailure) {
      hint = failure.hint;

      switch (failure.hint) {
        case 'contrasenas_no_coinciden':
          mensaje = 'Las contrasenas no coinciden';
          errorType = RecuperacionErrorType.contrasenasNoCoinciden;
          break;
        case 'contrasena_invalida':
          mensaje = 'La contrasena no cumple los requisitos de seguridad';
          errorType = RecuperacionErrorType.contrasenaInvalida;
          break;
        case 'contrasena_igual_anterior':
          mensaje = 'La nueva contrasena debe ser diferente a la anterior';
          errorType = RecuperacionErrorType.contrasenaIgualAnterior;
          break;
        default:
          mensaje = failure.message;
          errorType = RecuperacionErrorType.servidor;
      }
    }

    return _ErrorInfo(mensaje: mensaje, errorType: errorType, hint: hint);
  }
}

/// Clase auxiliar para mapeo de errores de token
class _TokenErrorInfo {
  final String mensaje;
  final TokenErrorType errorType;

  _TokenErrorInfo({required this.mensaje, required this.errorType});
}

/// Clase auxiliar para mapeo de errores generales
class _ErrorInfo {
  final String mensaje;
  final RecuperacionErrorType errorType;
  final String? hint;

  _ErrorInfo({required this.mensaje, required this.errorType, this.hint});
}
