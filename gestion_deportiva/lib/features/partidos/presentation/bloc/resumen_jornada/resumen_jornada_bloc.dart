import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/partidos_repository.dart';
import 'resumen_jornada_event.dart';
import 'resumen_jornada_state.dart';

/// BLoC para gestionar el resumen de jornada
/// E004-HU-007: Resumen de Jornada
///
/// Criterios de Aceptacion:
/// - CA-001: Mostrar tabla de posiciones con PJ, PG, PE, PP, GF, GC, DIF, PTS
/// - CA-002: Mostrar estadisticas generales de la jornada
/// - CA-003: Mostrar lista de goleadores con posicion
class ResumenJornadaBloc
    extends Bloc<ResumenJornadaEvent, ResumenJornadaState> {
  final PartidosRepository repository;

  ResumenJornadaBloc({required this.repository})
      : super(const ResumenJornadaInitial()) {
    on<CargarResumenJornada>(_onCargarResumenJornada);
    on<RefrescarResumen>(_onRefrescarResumen);
    on<ResetResumenJornada>(_onReset);
  }

  /// CA-001, CA-002, CA-003: Cargar resumen completo de la jornada
  Future<void> _onCargarResumenJornada(
    CargarResumenJornada event,
    Emitter<ResumenJornadaState> emit,
  ) async {
    emit(const ResumenJornadaLoading());

    final result = await repository.obtenerResumenJornada(event.fechaId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(ResumenJornadaError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          fechaId: event.fechaId,
        ));
      },
      (resumen) {
        if (resumen.success) {
          emit(ResumenJornadaLoaded(resumen: resumen));
        } else {
          emit(ResumenJornadaError(
            message: resumen.message.isNotEmpty
                ? resumen.message
                : 'Error al obtener resumen de jornada',
            fechaId: event.fechaId,
          ));
        }
      },
    );
  }

  /// Refrescar resumen manteniendo datos previos
  Future<void> _onRefrescarResumen(
    RefrescarResumen event,
    Emitter<ResumenJornadaState> emit,
  ) async {
    // Si hay datos previos, mostrar estado de refrescando
    if (state is ResumenJornadaLoaded) {
      final previousState = state as ResumenJornadaLoaded;
      emit(ResumenJornadaRefreshing(resumenPrevio: previousState.resumen));
    } else {
      emit(const ResumenJornadaLoading());
    }

    final result = await repository.obtenerResumenJornada(event.fechaId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(ResumenJornadaError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          fechaId: event.fechaId,
        ));
      },
      (resumen) {
        if (resumen.success) {
          emit(ResumenJornadaLoaded(resumen: resumen));
        } else {
          emit(ResumenJornadaError(
            message: resumen.message.isNotEmpty
                ? resumen.message
                : 'Error al refrescar resumen',
            fechaId: event.fechaId,
          ));
        }
      },
    );
  }

  /// Reiniciar estado
  void _onReset(
    ResetResumenJornada event,
    Emitter<ResumenJornadaState> emit,
  ) {
    emit(const ResumenJornadaInitial());
  }
}
