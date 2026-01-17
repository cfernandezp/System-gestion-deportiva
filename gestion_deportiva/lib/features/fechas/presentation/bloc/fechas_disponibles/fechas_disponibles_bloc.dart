import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../data/models/fecha_disponible_model.dart';
import '../../../domain/repositories/fechas_repository.dart';
import 'fechas_disponibles_event.dart';
import 'fechas_disponibles_state.dart';

/// BLoC para gestionar la lista de fechas disponibles
/// E003-HU-002: Inscribirse a Fecha
///
/// Muestra las fechas con estado 'abierta' para que el usuario
/// pueda ver y seleccionar a cual inscribirse.
///
/// RN-002: Solo fechas con estado 'abierta' permiten inscripcion
class FechasDisponiblesBloc
    extends Bloc<FechasDisponiblesEvent, FechasDisponiblesState> {
  final FechasRepository repository;

  FechasDisponiblesBloc({required this.repository})
      : super(const FechasDisponiblesInitial()) {
    on<CargarFechasDisponiblesEvent>(_onCargarFechas);
    on<RefrescarFechasDisponiblesEvent>(_onRefrescarFechas);
    on<ResetFechasDisponiblesEvent>(_onReset);
  }

  /// Cargar lista inicial de fechas disponibles
  Future<void> _onCargarFechas(
    CargarFechasDisponiblesEvent event,
    Emitter<FechasDisponiblesState> emit,
  ) async {
    emit(const FechasDisponiblesLoading());

    final result = await repository.listarFechasDisponibles();

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(FechasDisponiblesError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success) {
          emit(FechasDisponiblesCargadas(
            fechas: response.fechas,
            total: response.total,
          ));
        } else {
          emit(FechasDisponiblesError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cargar fechas disponibles',
          ));
        }
      },
    );
  }

  /// Refrescar lista de fechas manteniendo datos anteriores
  Future<void> _onRefrescarFechas(
    RefrescarFechasDisponiblesEvent event,
    Emitter<FechasDisponiblesState> emit,
  ) async {
    // Obtener fechas actuales para mantener UI
    final estadoActual = state;
    List<FechaDisponibleModel> fechasActuales = [];

    if (estadoActual is FechasDisponiblesCargadas) {
      fechasActuales = estadoActual.fechas;
    } else if (estadoActual is FechasDisponiblesError &&
        estadoActual.fechasAnteriores != null) {
      fechasActuales = estadoActual.fechasAnteriores!;
    }

    if (fechasActuales.isNotEmpty) {
      emit(FechasDisponiblesRefrescando(fechasActuales: fechasActuales));
    } else {
      emit(const FechasDisponiblesLoading());
    }

    final result = await repository.listarFechasDisponibles();

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(FechasDisponiblesError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          fechasAnteriores:
              fechasActuales.isNotEmpty ? fechasActuales : null,
        ));
      },
      (response) {
        if (response.success) {
          emit(FechasDisponiblesCargadas(
            fechas: response.fechas,
            total: response.total,
          ));
        } else {
          emit(FechasDisponiblesError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al refrescar fechas disponibles',
            fechasAnteriores:
                fechasActuales.isNotEmpty ? fechasActuales : null,
          ));
        }
      },
    );
  }

  /// Reiniciar estado del bloc
  void _onReset(
    ResetFechasDisponiblesEvent event,
    Emitter<FechasDisponiblesState> emit,
  ) {
    emit(const FechasDisponiblesInitial());
  }
}
