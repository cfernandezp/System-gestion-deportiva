import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/grupos_repository.dart';
import 'invitar_jugador_event.dart';
import 'invitar_jugador_state.dart';

/// Bloc para invitar jugadores al grupo
/// E001-HU-004: Invitar Jugador al Grupo
class InvitarJugadorBloc extends Bloc<InvitarJugadorEvent, InvitarJugadorState> {
  final GruposRepository repository;

  InvitarJugadorBloc({required this.repository}) : super(InvitarJugadorInitial()) {
    on<InvitarJugadorSubmitEvent>(_onInvitarJugador);
  }

  Future<void> _onInvitarJugador(
    InvitarJugadorSubmitEvent event,
    Emitter<InvitarJugadorState> emit,
  ) async {
    emit(InvitarJugadorLoading());

    final result = await repository.invitarJugadorGrupo(
      grupoId: event.grupoId,
      celular: event.celular,
    );

    result.fold(
      (failure) {
        final hint = failure is ServerFailure ? failure.hint : null;
        emit(InvitarJugadorError(failure.message, hint: hint));
      },
      (response) => emit(InvitarJugadorSuccess(response)),
    );
  }
}
