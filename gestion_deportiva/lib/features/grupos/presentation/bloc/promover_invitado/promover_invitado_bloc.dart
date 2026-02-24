import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/grupos_repository.dart';
import 'promover_invitado_event.dart';
import 'promover_invitado_state.dart';

/// Bloc para promover invitado a jugador
/// E002-HU-009: Promover Invitado a Jugador
class PromoverInvitadoBloc
    extends Bloc<PromoverInvitadoEvent, PromoverInvitadoState> {
  final GruposRepository repository;

  PromoverInvitadoBloc({required this.repository})
      : super(PromoverInvitadoInitial()) {
    on<PromoverInvitadoSubmitEvent>(_onSubmit);
  }

  Future<void> _onSubmit(
    PromoverInvitadoSubmitEvent event,
    Emitter<PromoverInvitadoState> emit,
  ) async {
    emit(PromoverInvitadoLoading());

    final result = await repository.promoverInvitadoAJugador(
      grupoId: event.grupoId,
      miembroId: event.miembroId,
      celular: event.celular,
    );

    result.fold(
      (failure) {
        // Detectar errores especificos por code del backend
        if (failure is ServerFailure) {
          // CA-003: Celular ya registrado en el sistema
          if (failure.code == 'CELULAR_YA_EXISTE') {
            emit(PromoverInvitadoCelularExiste(
              mensaje: failure.message,
              celular: event.celular,
            ));
            return;
          }
          // CA-007: Limite de jugadores alcanzado
          if (failure.code == 'JUGADOR_LIMIT_REACHED') {
            emit(PromoverInvitadoLimiteAlcanzado(mensaje: failure.message));
            return;
          }
        }
        // Error generico
        emit(PromoverInvitadoError(
          mensaje: failure.message,
          hint: failure is ServerFailure ? failure.hint : null,
        ));
      },
      (data) => emit(PromoverInvitadoSuccess(
        nombre: data['nombre'] ?? '',
        mensaje: 'Invitado promovido a jugador exitosamente',
      )),
    );
  }
}
