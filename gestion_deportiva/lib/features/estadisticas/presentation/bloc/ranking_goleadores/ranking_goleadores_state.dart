import 'package:equatable/equatable.dart';

import '../../../data/models/models.dart';

/// Estados del BLoC de ranking de goleadores
/// E006-HU-001: Ranking de Goleadores
abstract class RankingGoleadoresState extends Equatable {
  const RankingGoleadoresState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class RankingGoleadoresInitial extends RankingGoleadoresState {
  const RankingGoleadoresInitial();
}

/// Cargando ranking
class RankingGoleadoresLoading extends RankingGoleadoresState {
  /// Periodo que se esta cargando
  final PeriodoRanking periodo;

  const RankingGoleadoresLoading({
    this.periodo = PeriodoRanking.historico,
  });

  @override
  List<Object?> get props => [periodo];
}

/// Ranking cargado exitosamente
/// CA-001: Lista ordenada por goles
/// CA-002: Informacion completa por jugador
class RankingGoleadoresLoaded extends RankingGoleadoresState {
  /// Ranking completo
  final List<RankingGoleadorModel> ranking;

  /// Periodo actual
  final PeriodoRanking periodo;

  /// Total de jugadores con goles
  final int totalJugadores;

  /// Top 3 para podio (CA-006)
  final List<RankingGoleadorModel> top3;

  /// Resto del ranking (despues del top 3)
  final List<RankingGoleadorModel> restoRanking;

  /// Indica si hay podio completo (al menos 3 jugadores)
  final bool tienePodioCompleto;

  const RankingGoleadoresLoaded({
    required this.ranking,
    required this.periodo,
    required this.totalJugadores,
    required this.top3,
    required this.restoRanking,
    required this.tienePodioCompleto,
  });

  @override
  List<Object?> get props => [
        ranking,
        periodo,
        totalJugadores,
        top3,
        restoRanking,
        tienePodioCompleto,
      ];
}

/// CA-007: Ranking vacio
class RankingGoleadoresVacio extends RankingGoleadoresState {
  /// Periodo actual
  final PeriodoRanking periodo;

  /// Mensaje informativo
  final String mensaje;

  const RankingGoleadoresVacio({
    required this.periodo,
    required this.mensaje,
  });

  @override
  List<Object?> get props => [periodo, mensaje];
}

/// Refrescando ranking (mantiene datos actuales)
class RankingGoleadoresRefreshing extends RankingGoleadoresState {
  /// Ranking actual mientras se refresca
  final List<RankingGoleadorModel> rankingActual;

  /// Periodo actual
  final PeriodoRanking periodo;

  const RankingGoleadoresRefreshing({
    required this.rankingActual,
    required this.periodo,
  });

  @override
  List<Object?> get props => [rankingActual, periodo];
}

/// Error al cargar ranking
class RankingGoleadoresError extends RankingGoleadoresState {
  final String message;
  final String? code;
  final String? hint;
  final PeriodoRanking periodo;

  const RankingGoleadoresError({
    required this.message,
    this.code,
    this.hint,
    this.periodo = PeriodoRanking.historico,
  });

  @override
  List<Object?> get props => [message, code, hint, periodo];
}
