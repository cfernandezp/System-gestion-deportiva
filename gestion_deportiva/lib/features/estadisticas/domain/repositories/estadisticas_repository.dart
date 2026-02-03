import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/models.dart';

/// Interface del repositorio de estadisticas
/// E006-HU-001: Ranking de Goleadores
abstract class EstadisticasRepository {
  /// Obtiene el ranking de goleadores
  /// CA-001 a CA-007, RN-001 a RN-006
  Future<Either<Failure, RankingGoleadoresResponseModel>> obtenerRankingGoleadores({
    PeriodoRanking periodo = PeriodoRanking.historico,
  });
}
