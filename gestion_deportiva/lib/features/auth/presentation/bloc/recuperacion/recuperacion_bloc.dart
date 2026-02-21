import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'recuperacion_event.dart';
import 'recuperacion_state.dart';

/// Bloc para manejar la recuperacion de contrasena
/// Implementa E001-HU-007: Recuperacion de Contrasena
///
/// Flujo multi-paso:
/// 1. Identificar tipo (admin/jugador/no_encontrado)
/// 2A. Jugador: codigo del admin -> validar -> nueva contrasena
/// 2B. Admin: pregunta seguridad -> nueva contrasena
/// 2C. Admin fallback: email de respaldo -> codigo -> nueva contrasena
class RecuperacionBloc extends Bloc<RecuperacionEvent, RecuperacionState> {
  final AuthRepository repository;

  RecuperacionBloc({required this.repository})
      : super(const RecuperacionInitial()) {
    on<IdentificarTipoRecuperacionEvent>(_onIdentificarTipo);
    on<ValidarCodigoEvent>(_onValidarCodigo);
    on<RestablecerConCodigoEvent>(_onRestablecerConCodigo);
    on<RestablecerConPreguntaEvent>(_onRestablecerConPregunta);
    on<SolicitarEmailRecuperacionEvent>(_onSolicitarEmailRecuperacion);
    on<RecuperacionResetEvent>(_onReset);
  }

  /// Paso 1: Identificar tipo de recuperacion segun celular
  Future<void> _onIdentificarTipo(
    IdentificarTipoRecuperacionEvent event,
    Emitter<RecuperacionState> emit,
  ) async {
    emit(const RecuperacionLoading());

    final result = await repository.identificarTipoRecuperacion(
      celular: event.celular,
    );

    result.fold(
      (failure) {
        if (_esBloqueado(failure)) {
          emit(RecuperacionBloqueada(mensaje: failure.message));
        } else {
          emit(RecuperacionError(
            mensaje: failure.message,
            hint: failure is ServerFailure ? failure.hint : null,
          ));
        }
      },
      (tipoRecuperacion) {
        emit(TipoRecuperacionIdentificado(
          tipo: tipoRecuperacion.tipo,
          celular: event.celular,
          preguntaSeguridad: tipoRecuperacion.preguntaSeguridad,
          tieneEmailRespaldo: tipoRecuperacion.tieneEmailRespaldo,
          emailRespaldoMascara: tipoRecuperacion.emailRespaldoMascara,
          mensaje: tipoRecuperacion.mensaje,
        ));
      },
    );
  }

  /// Paso 2A/3: Validar codigo de recuperacion
  Future<void> _onValidarCodigo(
    ValidarCodigoEvent event,
    Emitter<RecuperacionState> emit,
  ) async {
    emit(const RecuperacionLoading());

    final result = await repository.validarCodigoRecuperacion(
      celular: event.celular,
      codigo: event.codigo,
    );

    result.fold(
      (failure) {
        if (_esBloqueado(failure)) {
          emit(RecuperacionBloqueada(mensaje: failure.message));
        } else {
          emit(RecuperacionError(
            mensaje: failure.message,
            hint: failure is ServerFailure ? failure.hint : null,
          ));
        }
      },
      (validacion) {
        if (validacion.codigoValido) {
          emit(CodigoValidado(
            celular: event.celular,
            codigo: event.codigo,
          ));
        } else {
          emit(RecuperacionError(
            mensaje: 'El codigo ingresado no es valido',
            hint: 'codigo_invalido',
          ));
        }
      },
    );
  }

  /// Paso final (jugador/email): Restablecer contrasena con codigo
  Future<void> _onRestablecerConCodigo(
    RestablecerConCodigoEvent event,
    Emitter<RecuperacionState> emit,
  ) async {
    emit(const RecuperacionLoading());

    final result = await repository.restablecerContrasenaConCodigo(
      celular: event.celular,
      codigo: event.codigo,
      nuevaContrasena: event.nuevaContrasena,
      confirmarContrasena: event.confirmarContrasena,
    );

    result.fold(
      (failure) {
        if (_esBloqueado(failure)) {
          emit(RecuperacionBloqueada(mensaje: failure.message));
        } else {
          emit(RecuperacionError(
            mensaje: failure.message,
            hint: failure is ServerFailure ? failure.hint : null,
          ));
        }
      },
      (resultado) {
        emit(RecuperacionExitosa(
          mensaje: resultado.mensaje,
          sesionesCerradas: resultado.sesionesCerradas,
        ));
      },
    );
  }

  /// Paso 2B (admin): Restablecer contrasena con pregunta de seguridad
  /// Maneja respuestas incorrectas con/sin email de respaldo
  Future<void> _onRestablecerConPregunta(
    RestablecerConPreguntaEvent event,
    Emitter<RecuperacionState> emit,
  ) async {
    emit(const RecuperacionLoading());

    final result = await repository.restablecerContrasenaConPregunta(
      celular: event.celular,
      respuesta: event.respuesta,
      nuevaContrasena: event.nuevaContrasena,
      confirmarContrasena: event.confirmarContrasena,
    );

    result.fold(
      (failure) {
        if (_esBloqueado(failure)) {
          emit(RecuperacionBloqueada(mensaje: failure.message));
          return;
        }

        final hint = failure is ServerFailure ? failure.hint ?? '' : '';

        // Parsear hint para detectar respuesta incorrecta con datos extra
        // Formato del datasource: "respuesta_incorrecta_con_email|j***@gmail.com"
        if (hint.startsWith('respuesta_incorrecta_con_email')) {
          final parts = hint.split('|');
          final emailMascara = parts.length > 1 ? parts[1] : '';
          emit(RespuestaIncorrectaConEmail(
            celular: event.celular,
            emailMascara: emailMascara,
          ));
        } else if (hint == 'respuesta_incorrecta_sin_email') {
          emit(RespuestaIncorrectaSinEmail(
            celular: event.celular,
            mensaje: failure.message,
          ));
        } else {
          emit(RecuperacionError(
            mensaje: failure.message,
            hint: hint,
          ));
        }
      },
      (resultado) {
        emit(RecuperacionExitosa(
          mensaje: resultado.mensaje,
          sesionesCerradas: resultado.sesionesCerradas,
        ));
      },
    );
  }

  /// Solicitar recuperacion via email de respaldo (admin fallback)
  Future<void> _onSolicitarEmailRecuperacion(
    SolicitarEmailRecuperacionEvent event,
    Emitter<RecuperacionState> emit,
  ) async {
    emit(const RecuperacionLoading());

    final result = await repository.solicitarRecuperacionEmailAdmin(
      celular: event.celular,
    );

    result.fold(
      (failure) {
        if (_esBloqueado(failure)) {
          emit(RecuperacionBloqueada(mensaje: failure.message));
        } else {
          emit(RecuperacionError(
            mensaje: failure.message,
            hint: failure is ServerFailure ? failure.hint : null,
          ));
        }
      },
      (emailResult) {
        emit(EmailRecuperacionEnviado(
          emailMascara: emailResult.emailRespaldoMascara,
          celular: event.celular,
          debugCodigo: emailResult.debugCodigo,
        ));
      },
    );
  }

  /// Resetear estado del bloc
  void _onReset(
    RecuperacionResetEvent event,
    Emitter<RecuperacionState> emit,
  ) {
    emit(const RecuperacionInitial());
  }

  /// Verifica si el error es de bloqueo temporal
  bool _esBloqueado(Failure failure) {
    if (failure is ServerFailure) {
      return failure.hint == 'cuenta_bloqueada_temporalmente';
    }
    return false;
  }
}
