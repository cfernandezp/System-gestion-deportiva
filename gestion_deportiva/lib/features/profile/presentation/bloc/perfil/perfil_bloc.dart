import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../data/models/perfil_model.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'perfil_event.dart';
import 'perfil_state.dart';

/// BLoC para gestionar el estado del perfil
/// E002-HU-001: Ver Perfil Propio
/// E002-HU-002: Editar Perfil Propio
class PerfilBloc extends Bloc<PerfilEvent, PerfilState> {
  final ProfileRepository repository;

  PerfilBloc({required this.repository}) : super(const PerfilInitial()) {
    on<CargarPerfilEvent>(_onCargarPerfil);
    on<RefrescarPerfilEvent>(_onRefrescarPerfil);
    on<ActualizarPerfilEvent>(_onActualizarPerfil);
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

  /// E002-HU-002: Maneja el evento de actualizar perfil
  /// CA-002: Campos editables: apodo, telefono, posicion, foto
  /// CA-004: Guardar cambios con confirmacion
  /// CA-005: Validacion de apodo unico (error si ya existe)
  /// RN-001 a RN-004: Validaciones de negocio en backend
  Future<void> _onActualizarPerfil(
    ActualizarPerfilEvent event,
    Emitter<PerfilState> emit,
  ) async {
    // Obtener perfil actual para mostrar durante el guardado
    final perfilActual = _obtenerPerfilActual();
    if (perfilActual == null) {
      emit(const PerfilError(
        message: 'No hay perfil cargado para actualizar',
      ));
      return;
    }

    // Mostrar estado de guardado
    emit(PerfilSaving(perfilActual: perfilActual));

    final result = await repository.actualizarPerfilPropio(
      apodo: event.apodo,
      telefono: event.telefono,
      posicionPreferida: event.posicionPreferida?.name,
      fotoUrl: event.fotoUrl,
    );

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(PerfilUpdateError(
          perfilActual: perfilActual,
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success && response.data != null) {
          emit(PerfilUpdateSuccess(
            perfil: response.data!,
            message: response.message,
          ));
        } else {
          emit(PerfilUpdateError(
            perfilActual: perfilActual,
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al actualizar el perfil',
          ));
        }
      },
    );
  }

  /// Obtiene el perfil actual del estado
  PerfilModel? _obtenerPerfilActual() {
    final currentState = state;
    if (currentState is PerfilLoaded) return currentState.perfil;
    if (currentState is PerfilRefreshing) return currentState.perfilActual;
    if (currentState is PerfilSaving) return currentState.perfilActual;
    if (currentState is PerfilUpdateSuccess) return currentState.perfil;
    if (currentState is PerfilUpdateError) return currentState.perfilActual;
    return null;
  }
}
