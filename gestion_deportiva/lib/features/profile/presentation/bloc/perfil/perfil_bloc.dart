import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'perfil_event.dart';
import 'perfil_state.dart';

/// BLoC para gestionar el estado del perfil
/// E002-HU-001: Ver Perfil Propio
class PerfilBloc extends Bloc<PerfilEvent, PerfilState> {
  final ProfileRepository repository;

  PerfilBloc({required this.repository}) : super(const PerfilInitial()) {
    on<CargarPerfilEvent>(_onCargarPerfil);
    on<RefrescarPerfilEvent>(_onRefrescarPerfil);
  }

  /// Maneja el evento de cargar perfil
  /// CA-001: Acceso al perfil desde seccion "Mi Perfil"
  /// RN-001: Solo puede ver su propio perfil (garantizado por RPC)
  Future<void> _onCargarPerfil(
    CargarPerfilEvent event,
    Emitter<PerfilState> emit,
  ) async {
    emit(const PerfilLoading());

    final result = await repository.obtenerPerfilPropio();

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(PerfilError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success && response.data != null) {
          emit(PerfilLoaded(perfil: response.data!));
        } else {
          emit(PerfilError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cargar el perfil',
          ));
        }
      },
    );
  }

  /// Maneja el evento de refrescar perfil (pull to refresh)
  Future<void> _onRefrescarPerfil(
    RefrescarPerfilEvent event,
    Emitter<PerfilState> emit,
  ) async {
    // Si ya tenemos un perfil cargado, mostramos estado de refresh
    if (state is PerfilLoaded) {
      final perfilActual = (state as PerfilLoaded).perfil;
      emit(PerfilRefreshing(perfilActual: perfilActual));
    }

    final result = await repository.obtenerPerfilPropio();

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(PerfilError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success && response.data != null) {
          emit(PerfilLoaded(perfil: response.data!));
        } else {
          emit(PerfilError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al refrescar el perfil',
          ));
        }
      },
    );
  }
}
