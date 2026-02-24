import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/estadisticas_repository.dart';
import 'estadisticas_mensuales_event.dart';
import 'estadisticas_mensuales_state.dart';

/// BLoC de Estadisticas Mensuales
/// E006-HU-005: Estadisticas agregadas por mes del grupo
class EstadisticasMensualesBloc
    extends Bloc<EstadisticasMensualesEvent, EstadisticasMensualesState> {
  final EstadisticasRepository repository;

  EstadisticasMensualesBloc({required this.repository})
      : super(const EstadisticasMensualesInitial()) {
    on<CargarEstadisticasMensualesEvent>(_onCargar);
    on<CambiarMesEvent>(_onCambiarMes);
  }

  Future<void> _onCargar(
    CargarEstadisticasMensualesEvent event,
    Emitter<EstadisticasMensualesState> emit,
  ) async {
    emit(const EstadisticasMensualesLoading());

    final now = DateTime.now();
    final anio = event.anio ?? now.year;
    final mes = event.mes ?? now.month;

    final result = await repository.obtenerEstadisticasMensuales(
      grupoId: event.grupoId,
      anio: anio,
      mes: mes,
    );

    result.fold(
      (failure) => emit(EstadisticasMensualesError(
        message: failure.message,
        hint: failure is ServerFailure ? failure.hint : null,
      )),
      (data) => emit(EstadisticasMensualesLoaded(
        estadisticas: data,
        anioSeleccionado: anio,
        mesSeleccionado: mes,
      )),
    );
  }

  /// CA-001: Cambiar mes -> recargar estadisticas
  Future<void> _onCambiarMes(
    CambiarMesEvent event,
    Emitter<EstadisticasMensualesState> emit,
  ) async {
    add(CargarEstadisticasMensualesEvent(
      grupoId: event.grupoId,
      anio: event.anio,
      mes: event.mes,
    ));
  }
}
