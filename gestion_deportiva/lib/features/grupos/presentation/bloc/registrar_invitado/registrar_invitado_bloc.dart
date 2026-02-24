import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/grupos_repository.dart';
import 'registrar_invitado_event.dart';
import 'registrar_invitado_state.dart';

/// Bloc para registrar invitado en el grupo
/// E002-HU-008: Registrar Invitado en el Grupo
class RegistrarInvitadoBloc
    extends Bloc<RegistrarInvitadoEvent, RegistrarInvitadoState> {
  final GruposRepository repository;

  RegistrarInvitadoBloc({required this.repository})
      : super(RegistrarInvitadoInitial()) {
    on<RegistrarInvitadoSubmitEvent>(_onSubmit);
  }

  Future<void> _onSubmit(
    RegistrarInvitadoSubmitEvent event,
    Emitter<RegistrarInvitadoState> emit,
  ) async {
    emit(RegistrarInvitadoLoading());

    final result = await repository.registrarInvitado(
      grupoId: event.grupoId,
      nombre: event.nombre,
    );

    result.fold(
      (failure) {
        // Detectar error de limite de invitados
        if (failure is ServerFailure &&
            failure.hint == 'limite_invitados') {
          emit(RegistrarInvitadoLimiteAlcanzado(mensaje: failure.message));
        } else {
          emit(RegistrarInvitadoError(
            mensaje: failure.message,
            hint: failure is ServerFailure ? failure.hint : null,
          ));
        }
      },
      (data) => emit(RegistrarInvitadoSuccess(
        nombre: data['nombre'] ?? event.nombre,
        mensaje: 'Invitado registrado exitosamente',
      )),
    );
  }
}
