import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/partidos_repository.dart';
import 'lista_partidos_event.dart';
import 'lista_partidos_state.dart';

/// BLoC para gestionar la lista de partidos de una fecha
class ListaPartidosBloc extends Bloc<ListaPartidosEvent, ListaPartidosState> {
  final PartidosRepository repository;

  ListaPartidosBloc({required this.repository})
      : super(const ListaPartidosInitial()) {
    on<CargarPartidosEvent>(_onCargarPartidos);
    on<RefrescarPartidosEvent>(_onRefrescarPartidos);
  }

  /// Carga la lista de partidos de una fecha
  Future<void> _onCargarPartidos(
    CargarPartidosEvent event,
    Emitter<ListaPartidosState> emit,
  ) async {
    emit(const ListaPartidosLoading());

    final result = await repository.listarPartidosFecha(event.fechaId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(ListaPartidosError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success) {
          emit(ListaPartidosLoaded(
            partidos: response.partidos,
            total: response.total,
            puedeCrearPartido: response.puedeCrearPartido,
            message: response.message,
          ));
        } else {
          emit(ListaPartidosError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cargar partidos',
          ));
        }
      },
    );
  }

  /// Refresca la lista de partidos (misma logica que cargar)
  Future<void> _onRefrescarPartidos(
    RefrescarPartidosEvent event,
    Emitter<ListaPartidosState> emit,
  ) async {
    // No emitimos loading para evitar parpadeo en refresh
    final result = await repository.listarPartidosFecha(event.fechaId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(ListaPartidosError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success) {
          emit(ListaPartidosLoaded(
            partidos: response.partidos,
            total: response.total,
            puedeCrearPartido: response.puedeCrearPartido,
            message: response.message,
          ));
        } else {
          emit(ListaPartidosError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al refrescar partidos',
          ));
        }
      },
    );
  }
}
