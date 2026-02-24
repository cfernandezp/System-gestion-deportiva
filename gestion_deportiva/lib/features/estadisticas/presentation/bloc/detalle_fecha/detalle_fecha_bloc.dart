import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/estadisticas_repository.dart';
import 'detalle_fecha_event.dart';
import 'detalle_fecha_state.dart';

/// BLoC de Detalle de Fecha
/// E006-HU-004: Detalle de resultados de una fecha especifica
class DetalleFechaBloc extends Bloc<DetalleFechaEvent, DetalleFechaState> {
  final EstadisticasRepository repository;

  DetalleFechaBloc({required this.repository})
      : super(const DetalleFechaInitial()) {
    on<CargarDetalleFechaEvent>(_onCargar);
  }

  /// CA-002: Cargar detalle de fecha con partidos, tabla, goleadores y asistentes
  Future<void> _onCargar(
    CargarDetalleFechaEvent event,
    Emitter<DetalleFechaState> emit,
  ) async {
    emit(const DetalleFechaLoading());

    final result = await repository.obtenerDetalleFechaResultados(
      fechaId: event.fechaId,
      grupoId: event.grupoId,
    );

    result.fold(
      (failure) => emit(DetalleFechaError(
        message: failure.message,
        hint: failure is ServerFailure ? failure.hint : null,
      )),
      (data) => emit(DetalleFechaLoaded(detalle: data)),
    );
  }
}
