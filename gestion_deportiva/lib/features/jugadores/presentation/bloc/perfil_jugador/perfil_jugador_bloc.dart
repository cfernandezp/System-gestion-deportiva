import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/jugadores_repository.dart';
import 'perfil_jugador_event.dart';
import 'perfil_jugador_state.dart';

/// BLoC para gestionar el perfil de un jugador
/// E002-HU-004: Ver Perfil de Otro Jugador
class PerfilJugadorBloc extends Bloc<PerfilJugadorEvent, PerfilJugadorState> {
  final JugadoresRepository repository;
  String? _currentJugadorId;

  PerfilJugadorBloc({required this.repository})
      : super(const PerfilJugadorInitial()) {
    on<CargarPerfilJugadorEvent>(_onCargarPerfil);
    on<RefrescarPerfilJugadorEvent>(_onRefrescarPerfil);
  }

  /// Extrae code y hint de ServerFailure si aplica
  PerfilJugadorError _buildErrorState(Failure failure) {
    if (failure is ServerFailure) {
      return PerfilJugadorError(
        message: failure.message,
        code: failure.code,
        hint: failure.hint,
      );
    }
    return PerfilJugadorError(message: failure.message);
  }

  /// Maneja el evento de cargar perfil
  /// CA-001: Acceso desde lista de jugadores
  Future<void> _onCargarPerfil(
    CargarPerfilJugadorEvent event,
    Emitter<PerfilJugadorState> emit,
  ) async {
    _currentJugadorId = event.jugadorId;
    emit(const PerfilJugadorLoading());

    final result = await repository.obtenerPerfilJugador(event.jugadorId);

    result.fold(
      (failure) => emit(_buildErrorState(failure)),
      (response) {
        if (response.success && response.data != null) {
          emit(PerfilJugadorLoaded(
            perfil: response.data!,
            message: response.message,
          ));
        } else {
          emit(PerfilJugadorError(
            message: response.message.isNotEmpty
                ? response.message
                : 'No se pudo cargar el perfil del jugador',
          ));
        }
      },
    );
  }

  /// Maneja el evento de refrescar perfil
  Future<void> _onRefrescarPerfil(
    RefrescarPerfilJugadorEvent event,
    Emitter<PerfilJugadorState> emit,
  ) async {
    if (_currentJugadorId == null) return;

    // Mantener estado actual mientras se refresca
    final currentState = state;
    if (currentState is PerfilJugadorLoaded) {
      // No mostrar loading, mantener datos actuales
    } else {
      emit(const PerfilJugadorLoading());
    }

    final result = await repository.obtenerPerfilJugador(_currentJugadorId!);

    result.fold(
      (failure) => emit(_buildErrorState(failure)),
      (response) {
        if (response.success && response.data != null) {
          emit(PerfilJugadorLoaded(
            perfil: response.data!,
            message: response.message,
          ));
        } else {
          emit(PerfilJugadorError(
            message: response.message.isNotEmpty
                ? response.message
                : 'No se pudo refrescar el perfil del jugador',
          ));
        }
      },
    );
  }
}
