import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../data/models/obtener_asignaciones_response_model.dart';
import '../../../domain/repositories/fechas_repository.dart';
import 'asignaciones_event.dart';
import 'asignaciones_state.dart';

/// BLoC para gestionar asignaciones de equipos
/// E003-HU-005: Asignar Equipos
///
/// Criterios de Aceptacion:
/// - CA-001: Lista de inscritos y equipos disponibles
/// - CA-002: Equipos segun formato (2 o 3)
/// - CA-003: Colores distintivos
/// - CA-004: Asignacion drag-drop
/// - CA-005: Asignacion con selector
/// - CA-006: Advertencia de desbalance
/// - CA-007: Confirmar asignacion
/// - CA-008: Modificar antes de iniciar
///
/// Reglas de Negocio:
/// - RN-001: Solo admin aprobado
/// - RN-002: Solo fechas cerradas
/// - RN-003: Equipos segun duracion
/// - RN-004: Colores predefinidos
/// - RN-005: Asignacion completa requerida
/// - RN-006: Balance de equipos
/// - RN-007: Notificacion de asignacion
/// - RN-008: Modificacion pre-partido
class AsignacionesBloc extends Bloc<AsignacionesEvent, AsignacionesState> {
  final FechasRepository repository;

  AsignacionesBloc({required this.repository})
      : super(const AsignacionesInitial()) {
    on<CargarAsignacionesEvent>(_onCargarAsignaciones);
    on<AsignarEquipoEvent>(_onAsignarEquipo);
    on<DesasignarEquipoEvent>(_onDesasignarEquipo);
    on<ConfirmarEquiposEvent>(_onConfirmarEquipos);
    on<ResetAsignacionesEvent>(_onReset);
  }

  /// CA-001, CA-002, CA-003: Cargar asignaciones de una fecha
  Future<void> _onCargarAsignaciones(
    CargarAsignacionesEvent event,
    Emitter<AsignacionesState> emit,
  ) async {
    emit(const AsignacionesLoading());

    final result = await repository.obtenerAsignaciones(event.fechaId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(AsignacionesError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success && response.data != null) {
          emit(AsignacionesLoaded(
            data: response.data!,
            message: response.message,
          ));
        } else {
          emit(const AsignacionesError(
            message: 'Error inesperado al cargar asignaciones',
          ));
        }
      },
    );
  }

  /// CA-004, CA-005, CA-008: Asignar jugador a equipo
  /// RN-001, RN-002, RN-004, RN-008: Validaciones en backend
  Future<void> _onAsignarEquipo(
    AsignarEquipoEvent event,
    Emitter<AsignacionesState> emit,
  ) async {
    // Obtener datos actuales
    final currentState = state;
    late final ObtenerAsignacionesDataModel currentData;

    if (currentState is AsignacionesLoaded) {
      currentData = currentState.data;
    } else if (currentState is EquipoAsignado) {
      currentData = currentState.data;
    } else if (currentState is AsignarEquipoError) {
      currentData = currentState.data;
    } else if (currentState is AsignandoEquipo) {
      // Si ya estamos asignando, usar los datos del estado actual
      currentData = currentState.data;
    } else {
      emit(const AsignacionesError(
        message: 'Estado invalido para asignar equipo',
      ));
      return;
    }

    // Emitir estado de carga manteniendo datos
    emit(AsignandoEquipo(
      data: currentData,
      usuarioId: event.usuarioId,
    ));

    final result = await repository.asignarEquipo(
      fechaId: event.fechaId,
      usuarioId: event.usuarioId,
      equipo: event.equipo,
    );

    // Usar patron imperativo para evitar emit dentro de callbacks async
    if (result.isLeft()) {
      final failure = result.fold((l) => l, (r) => null)!;
      final serverFailure = failure is ServerFailure ? failure : null;
      emit(AsignarEquipoError(
        data: currentData,
        message: failure.message,
        hint: serverFailure?.hint,
      ));
      return;
    }

    final response = result.fold((l) => null, (r) => r)!;
    if (!response.success || response.data == null) {
      emit(AsignarEquipoError(
        data: currentData,
        message: 'Error inesperado al asignar equipo',
      ));
      return;
    }

    // Recargar asignaciones para obtener datos actualizados
    final reloadResult = await repository.obtenerAsignaciones(event.fechaId);

    if (reloadResult.isLeft()) {
      // Si falla recarga, mostrar exito con datos anteriores
      emit(EquipoAsignado(
        data: currentData,
        asignacion: response.data!,
        message: response.message,
      ));
      return;
    }

    final reloadResponse = reloadResult.fold((l) => null, (r) => r)!;
    if (reloadResponse.success && reloadResponse.data != null) {
      emit(EquipoAsignado(
        data: reloadResponse.data!,
        asignacion: response.data!,
        message: response.message,
      ));
    } else {
      emit(EquipoAsignado(
        data: currentData,
        asignacion: response.data!,
        message: response.message,
      ));
    }
  }

  /// Desasignar jugador de equipo (devolverlo a Sin Asignar)
  /// RN-001, RN-002, RN-008: Validaciones en backend
  Future<void> _onDesasignarEquipo(
    DesasignarEquipoEvent event,
    Emitter<AsignacionesState> emit,
  ) async {
    // Obtener datos actuales
    final currentState = state;
    late final ObtenerAsignacionesDataModel currentData;

    if (currentState is AsignacionesLoaded) {
      currentData = currentState.data;
    } else if (currentState is EquipoAsignado) {
      currentData = currentState.data;
    } else if (currentState is EquipoDesasignado) {
      currentData = currentState.data;
    } else if (currentState is AsignarEquipoError) {
      currentData = currentState.data;
    } else if (currentState is DesasignarEquipoError) {
      currentData = currentState.data;
    } else if (currentState is DesasignandoEquipo) {
      currentData = currentState.data;
    } else {
      emit(const AsignacionesError(
        message: 'Estado invalido para desasignar equipo',
      ));
      return;
    }

    // Emitir estado de carga manteniendo datos
    emit(DesasignandoEquipo(
      data: currentData,
      usuarioId: event.usuarioId,
    ));

    final result = await repository.desasignarEquipo(
      fechaId: event.fechaId,
      usuarioId: event.usuarioId,
    );

    // Usar patron imperativo para evitar emit dentro de callbacks async
    if (result.isLeft()) {
      final failure = result.fold((l) => l, (r) => null)!;
      final serverFailure = failure is ServerFailure ? failure : null;
      emit(DesasignarEquipoError(
        data: currentData,
        message: failure.message,
        hint: serverFailure?.hint,
      ));
      return;
    }

    final response = result.fold((l) => null, (r) => r)!;
    if (!response.success || response.data == null) {
      emit(DesasignarEquipoError(
        data: currentData,
        message: 'Error inesperado al desasignar equipo',
      ));
      return;
    }

    // Recargar asignaciones para obtener datos actualizados
    final reloadResult = await repository.obtenerAsignaciones(event.fechaId);

    if (reloadResult.isLeft()) {
      // Si falla recarga, mostrar exito con datos anteriores
      emit(EquipoDesasignado(
        data: currentData,
        usuarioNombre: response.data!.usuarioNombre,
        equipoAnterior: response.data!.equipoAnterior,
        message: response.message,
      ));
      return;
    }

    final reloadResponse = reloadResult.fold((l) => null, (r) => r)!;
    if (reloadResponse.success && reloadResponse.data != null) {
      emit(EquipoDesasignado(
        data: reloadResponse.data!,
        usuarioNombre: response.data!.usuarioNombre,
        equipoAnterior: response.data!.equipoAnterior,
        message: response.message,
      ));
    } else {
      emit(EquipoDesasignado(
        data: currentData,
        usuarioNombre: response.data!.usuarioNombre,
        equipoAnterior: response.data!.equipoAnterior,
        message: response.message,
      ));
    }
  }

  /// CA-007: Confirmar todas las asignaciones
  /// RN-005, RN-006, RN-007: Validaciones en backend
  Future<void> _onConfirmarEquipos(
    ConfirmarEquiposEvent event,
    Emitter<AsignacionesState> emit,
  ) async {
    // Obtener datos actuales
    final currentState = state;
    late final ObtenerAsignacionesDataModel currentData;

    if (currentState is AsignacionesLoaded) {
      currentData = currentState.data;
    } else if (currentState is EquipoAsignado) {
      currentData = currentState.data;
    } else if (currentState is ConfirmarEquiposError) {
      currentData = currentState.data;
    } else {
      emit(const AsignacionesError(
        message: 'Estado invalido para confirmar equipos',
      ));
      return;
    }

    // Emitir estado de carga
    emit(ConfirmandoEquipos(data: currentData));

    final result = await repository.confirmarEquipos(event.fechaId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(ConfirmarEquiposError(
          data: currentData,
          message: failure.message,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success && response.data != null) {
          emit(EquiposConfirmados(
            confirmacion: response.data!,
            message: response.message,
          ));
        } else {
          emit(ConfirmarEquiposError(
            data: currentData,
            message: 'Error inesperado al confirmar equipos',
          ));
        }
      },
    );
  }

  /// Reiniciar estado del bloc
  void _onReset(
    ResetAsignacionesEvent event,
    Emitter<AsignacionesState> emit,
  ) {
    emit(const AsignacionesInitial());
  }
}
