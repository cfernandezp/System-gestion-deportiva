import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/estadisticas_repository.dart';
import 'resultados_fecha_event.dart';
import 'resultados_fecha_state.dart';

/// BLoC de Resultados por Fecha
/// E006-HU-004: Historial de fechas finalizadas con filtros
class ResultadosFechaBloc
    extends Bloc<ResultadosFechaEvent, ResultadosFechaState> {
  final EstadisticasRepository repository;

  /// Almacena el grupoId para re-usar en filtros
  String _grupoId = '';

  ResultadosFechaBloc({required this.repository})
      : super(const ResultadosFechaInitial()) {
    on<CargarHistorialFechasEvent>(_onCargar);
    on<CambiarFiltroEvent>(_onCambiarFiltro);
  }

  /// CA-001: Cargar historial de fechas
  Future<void> _onCargar(
    CargarHistorialFechasEvent event,
    Emitter<ResultadosFechaState> emit,
  ) async {
    _grupoId = event.grupoId;
    emit(const ResultadosFechaLoading());

    final result = await repository.obtenerHistorialFechas(
      grupoId: event.grupoId,
      anio: event.anio,
      mes: event.mes,
      soloMias: event.soloMias,
    );

    result.fold(
      (failure) => emit(ResultadosFechaError(
        message: failure.message,
        hint: failure is ServerFailure ? failure.hint : null,
      )),
      (data) => emit(HistorialFechasLoaded(
        historial: data,
        anioActual: event.anio,
        mesActual: event.mes,
        soloMias: event.soloMias,
      )),
    );
  }

  /// CA-007: Cambiar filtros y recargar
  Future<void> _onCambiarFiltro(
    CambiarFiltroEvent event,
    Emitter<ResultadosFechaState> emit,
  ) async {
    // Obtener filtros actuales del state previo
    int? anio = event.anio;
    int? mes = event.mes;
    bool soloMias = event.soloMias ?? false;

    if (state is HistorialFechasLoaded) {
      final currentState = state as HistorialFechasLoaded;
      // Si no se especifica, mantener los filtros actuales
      // Pero si se pasa explicitamente null, se limpia el filtro
      anio ??= currentState.anioActual;
      mes ??= currentState.mesActual;
      soloMias = event.soloMias ?? currentState.soloMias;
    }

    emit(const ResultadosFechaLoading());

    final result = await repository.obtenerHistorialFechas(
      grupoId: _grupoId,
      anio: anio,
      mes: mes,
      soloMias: soloMias,
    );

    result.fold(
      (failure) => emit(ResultadosFechaError(
        message: failure.message,
        hint: failure is ServerFailure ? failure.hint : null,
      )),
      (data) => emit(HistorialFechasLoaded(
        historial: data,
        anioActual: anio,
        mesActual: mes,
        soloMias: soloMias,
      )),
    );
  }
}
