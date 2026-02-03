import 'package:equatable/equatable.dart';

import 'ranking_goleador_model.dart';

/// Enum para los periodos de filtrado del ranking
/// RN-005: Periodos de Filtrado
enum PeriodoRanking {
  historico,
  esteAno,
  esteMes,
  ultimaFecha;

  /// Valor para enviar al backend (snake_case)
  String get valor {
    switch (this) {
      case PeriodoRanking.historico:
        return 'historico';
      case PeriodoRanking.esteAno:
        return 'este_ano';
      case PeriodoRanking.esteMes:
        return 'este_mes';
      case PeriodoRanking.ultimaFecha:
        return 'ultima_fecha';
    }
  }

  /// Nombre para mostrar en UI
  String get displayName {
    switch (this) {
      case PeriodoRanking.historico:
        return 'Historico';
      case PeriodoRanking.esteAno:
        return 'Este ano';
      case PeriodoRanking.esteMes:
        return 'Este mes';
      case PeriodoRanking.ultimaFecha:
        return 'Ultima fecha';
    }
  }

  /// Crea instancia desde string del backend
  static PeriodoRanking fromString(String value) {
    switch (value) {
      case 'este_ano':
        return PeriodoRanking.esteAno;
      case 'este_mes':
        return PeriodoRanking.esteMes;
      case 'ultima_fecha':
        return PeriodoRanking.ultimaFecha;
      case 'historico':
      default:
        return PeriodoRanking.historico;
    }
  }
}

/// Modelo de respuesta del ranking de goleadores
/// E006-HU-001: Ranking de Goleadores
class RankingGoleadoresResponseModel extends Equatable {
  /// Periodo del ranking
  final PeriodoRanking periodo;

  /// Lista de goleadores ordenados por posicion
  final List<RankingGoleadorModel> ranking;

  /// Total de jugadores con goles
  final int totalJugadores;

  /// Mensaje informativo (usado cuando no hay datos - CA-007)
  final String? mensaje;

  const RankingGoleadoresResponseModel({
    required this.periodo,
    required this.ranking,
    required this.totalJugadores,
    this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Response format: { success: true, data: { periodo, ranking, total_jugadores, mensaje? } }
  factory RankingGoleadoresResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final rankingList = data['ranking'] as List? ?? [];

    return RankingGoleadoresResponseModel(
      periodo: PeriodoRanking.fromString(data['periodo'] ?? 'historico'),
      ranking: rankingList
          .map((item) =>
              RankingGoleadorModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalJugadores: data['total_jugadores'] ?? 0,
      mensaje: data['mensaje'],
    );
  }

  /// Verifica si el ranking esta vacio (CA-007)
  bool get estaVacio => ranking.isEmpty;

  /// Obtiene el top 3 para el podio (CA-006)
  List<RankingGoleadorModel> get top3 =>
      ranking.where((g) => g.esTop3).toList();

  /// Obtiene el resto del ranking (sin top 3)
  List<RankingGoleadorModel> get restoRanking =>
      ranking.where((g) => !g.esTop3).toList();

  /// Verifica si hay suficientes para mostrar podio (al menos 3)
  bool get tienePodioCompleto => ranking.length >= 3;

  @override
  List<Object?> get props => [periodo, ranking, totalJugadores, mensaje];
}
