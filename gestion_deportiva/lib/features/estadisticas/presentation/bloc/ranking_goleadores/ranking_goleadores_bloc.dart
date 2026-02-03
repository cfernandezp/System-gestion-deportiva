import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../data/models/models.dart';
import '../../../domain/repositories/estadisticas_repository.dart';
import 'ranking_goleadores_event.dart';
import 'ranking_goleadores_state.dart';

/// BLoC para gestionar el estado del ranking de goleadores
/// E006-HU-001: Ranking de Goleadores
class RankingGoleadoresBloc
    extends Bloc<RankingGoleadoresEvent, RankingGoleadoresState> {
  final EstadisticasRepository repository;

  /// Periodo actual seleccionado
  PeriodoRanking _periodoActual = PeriodoRanking.historico;

  RankingGoleadoresBloc({required this.repository})
      : super(const RankingGoleadoresInitial()) {
    on<CargarRankingEvent>(_onCargarRanking);
    on<CambiarPeriodoEvent>(_onCambiarPeriodo);
    on<RefrescarRankingEvent>(_onRefrescarRanking);
  }

  /// CA-001: Cargar ranking de goleadores
  Future<void> _onCargarRanking(
    CargarRankingEvent event,
    Emitter<RankingGoleadoresState> emit,
  ) async {
    emit(RankingGoleadoresLoading(periodo: _periodoActual));
    await _cargarRanking(emit);
  }

  /// CA-003: Cambiar periodo de filtrado
  Future<void> _onCambiarPeriodo(
    CambiarPeriodoEvent event,
    Emitter<RankingGoleadoresState> emit,
  ) async {
    // Si el periodo es el mismo, no hacer nada
    if (event.periodo == _periodoActual) return;

    _periodoActual = event.periodo;

    // Mantener datos actuales mientras carga
    final rankingActual = _obtenerRankingActual();
    if (rankingActual.isNotEmpty) {
      emit(RankingGoleadoresRefreshing(
        rankingActual: rankingActual,
        periodo: _periodoActual,
      ));
    } else {
      emit(RankingGoleadoresLoading(periodo: _periodoActual));
    }

    await _cargarRanking(emit);
  }

  /// Refrescar ranking (pull to refresh)
  Future<void> _onRefrescarRanking(
    RefrescarRankingEvent event,
    Emitter<RankingGoleadoresState> emit,
  ) async {
    final rankingActual = _obtenerRankingActual();
    if (rankingActual.isNotEmpty) {
      emit(RankingGoleadoresRefreshing(
        rankingActual: rankingActual,
        periodo: _periodoActual,
      ));
    }
    await _cargarRanking(emit);
  }

  /// Metodo interno para cargar ranking con periodo actual
  Future<void> _cargarRanking(Emitter<RankingGoleadoresState> emit) async {
    final result = await repository.obtenerRankingGoleadores(
      periodo: _periodoActual,
    );

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(RankingGoleadoresError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          periodo: _periodoActual,
        ));
      },
      (response) {
        if (response.estaVacio) {
          // CA-007: Ranking vacio
          emit(RankingGoleadoresVacio(
            periodo: response.periodo,
            mensaje: response.mensaje ?? 'No hay goles registrados en este periodo',
          ));
        } else {
          emit(RankingGoleadoresLoaded(
            ranking: response.ranking,
            periodo: response.periodo,
            totalJugadores: response.totalJugadores,
            top3: response.top3,
            restoRanking: response.restoRanking,
            tienePodioCompleto: response.tienePodioCompleto,
          ));
        }
        // Actualizar periodo con la respuesta del servidor
        _periodoActual = response.periodo;
      },
    );
  }

  /// Obtiene el ranking del estado actual
  List<RankingGoleadorModel> _obtenerRankingActual() {
    final currentState = state;
    if (currentState is RankingGoleadoresLoaded) return currentState.ranking;
    if (currentState is RankingGoleadoresRefreshing) {
      return currentState.rankingActual;
    }
    return [];
  }

  /// Getter para el periodo actual (para UI)
  PeriodoRanking get periodoActual => _periodoActual;
}
