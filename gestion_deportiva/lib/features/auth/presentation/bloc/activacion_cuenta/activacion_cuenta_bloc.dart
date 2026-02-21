import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'activacion_cuenta_event.dart';
import 'activacion_cuenta_state.dart';

/// Bloc para activacion de cuenta de jugador invitado
/// E001-HU-005: Activacion de Cuenta de Jugador Invitado
class ActivacionCuentaBloc extends Bloc<ActivacionCuentaEvent, ActivacionCuentaState> {
  final AuthRepository repository;

  ActivacionCuentaBloc({required this.repository}) : super(ActivacionCuentaInitial()) {
    on<VerificarInvitacionEvent>(_onVerificarInvitacion);
    on<ActivarCuentaEvent>(_onActivarCuenta);
    on<ResetActivacionEvent>(_onReset);
  }

  /// Volver al paso 1
  void _onReset(
    ResetActivacionEvent event,
    Emitter<ActivacionCuentaState> emit,
  ) {
    emit(ActivacionCuentaInitial());
  }

  /// CA-001, CA-002, CA-004: Verificar invitacion pendiente
  Future<void> _onVerificarInvitacion(
    VerificarInvitacionEvent event,
    Emitter<ActivacionCuentaState> emit,
  ) async {
    emit(ActivacionCuentaLoading());

    final result = await repository.verificarInvitacionPendiente(
      celular: event.celular,
    );

    result.fold(
      (failure) {
        final hint = failure is ServerFailure ? failure.hint : null;
        emit(ActivacionCuentaError(failure.message, hint: hint));
      },
      (verificacion) {
        if (verificacion.tieneInvitacion) {
          // CA-001: Tiene invitacion - avanzar al formulario
          emit(InvitacionVerificada(
            verificacion: verificacion,
            celular: event.celular,
          ));
        } else {
          // CA-002 / CA-004: No tiene invitacion o ya activo
          emit(InvitacionNoEncontrada(
            mensaje: verificacion.mensaje,
            yaActivo: verificacion.yaActivo,
          ));
        }
      },
    );
  }

  /// CA-001, CA-005, CA-006: Activar cuenta
  Future<void> _onActivarCuenta(
    ActivarCuentaEvent event,
    Emitter<ActivacionCuentaState> emit,
  ) async {
    emit(ActivacionCuentaLoading());

    final result = await repository.activarCuentaJugador(
      celular: event.celular,
      nombreCompleto: event.nombreCompleto,
      password: event.password,
    );

    result.fold(
      (failure) {
        final hint = failure is ServerFailure ? failure.hint : null;
        emit(ActivacionCuentaError(failure.message, hint: hint));
      },
      (response) => emit(ActivacionCuentaSuccess(response)),
    );
  }
}
