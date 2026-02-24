import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/estadisticas_repository.dart';
import 'mis_estadisticas_event.dart';
import 'mis_estadisticas_state.dart';

/// BLoC de Mis Estadisticas
/// E006-HU-003: Dashboard personal del jugador
class MisEstadisticasBloc extends Bloc<MisEstadisticasEvent, MisEstadisticasState> {
  final EstadisticasRepository repository;

  MisEstadisticasBloc({required this.repository})
      : super(const MisEstadisticasInitial()) {
    on<CargarMisEstadisticasEvent>(_onCargar);
  }

  Future<void> _onCargar(
    CargarMisEstadisticasEvent event,
    Emitter<MisEstadisticasState> emit,
  ) async {
    emit(const MisEstadisticasLoading());

    final result = await repository.obtenerMisEstadisticas(
      grupoId: event.grupoId,
    );

    result.fold(
      (failure) => emit(MisEstadisticasError(
        message: failure.message,
        hint: failure is ServerFailure ? failure.hint : null,
      )),
      (data) => emit(MisEstadisticasLoaded(estadisticas: data)),
    );
  }
}
