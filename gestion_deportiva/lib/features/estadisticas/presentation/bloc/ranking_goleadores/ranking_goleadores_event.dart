import 'package:equatable/equatable.dart';

import '../../../data/models/models.dart';

/// Eventos del BLoC de ranking de goleadores
/// E006-HU-001: Ranking de Goleadores
abstract class RankingGoleadoresEvent extends Equatable {
  const RankingGoleadoresEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001: Cargar ranking de goleadores
class CargarRankingEvent extends RankingGoleadoresEvent {
  const CargarRankingEvent();
}

/// CA-003: Cambiar periodo de filtrado
class CambiarPeriodoEvent extends RankingGoleadoresEvent {
  final PeriodoRanking periodo;

  const CambiarPeriodoEvent(this.periodo);

  @override
  List<Object?> get props => [periodo];
}

/// Refrescar ranking (pull to refresh)
class RefrescarRankingEvent extends RankingGoleadoresEvent {
  const RefrescarRankingEvent();
}
