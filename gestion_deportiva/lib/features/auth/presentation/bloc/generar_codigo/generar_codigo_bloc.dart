import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'generar_codigo_event.dart';
import 'generar_codigo_state.dart';

/// Bloc para generar codigo de recuperacion de contrasena
/// E001-HU-007: Usado por admin/coadmin para generar codigo para un jugador
class GenerarCodigoBloc extends Bloc<GenerarCodigoEvent, GenerarCodigoState> {
  final AuthRepository repository;

  GenerarCodigoBloc({required this.repository})
      : super(GenerarCodigoInitial()) {
    on<GenerarCodigoRecuperacionEvent>(_onGenerarCodigo);
    on<ResetGenerarCodigoEvent>(_onReset);
  }

  /// Genera codigo de recuperacion para un jugador
  Future<void> _onGenerarCodigo(
    GenerarCodigoRecuperacionEvent event,
    Emitter<GenerarCodigoState> emit,
  ) async {
    emit(GenerarCodigoLoading());

    final result = await repository.generarCodigoRecuperacion(
      celularJugador: event.celularJugador,
    );

    result.fold(
      (failure) {
        final hint = failure is ServerFailure ? failure.hint : null;
        emit(GenerarCodigoError(
          mensaje: failure.message,
          hint: hint,
        ));
      },
      (codigoResult) {
        emit(CodigoGenerado(
          codigo: codigoResult.codigo,
          celularJugador: codigoResult.celularJugador,
          expiraEnMinutos: codigoResult.expiraEnMinutos,
          mensajeParaJugador: codigoResult.mensajeParaJugador,
        ));
      },
    );
  }

  /// Resetear al estado inicial
  void _onReset(
    ResetGenerarCodigoEvent event,
    Emitter<GenerarCodigoState> emit,
  ) {
    emit(GenerarCodigoInitial());
  }
}
