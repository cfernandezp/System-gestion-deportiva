import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/models.dart';

/// Interface del repositorio de estadisticas
/// E006-HU-001: Ranking de Goleadores
/// E006-HU-003: Mis Estadisticas
/// E006-HU-004: Resultados por Fecha
abstract class EstadisticasRepository {
  /// Obtiene el ranking de goleadores
  /// CA-001 a CA-007, RN-001 a RN-006
  Future<Either<Failure, RankingGoleadoresResponseModel>> obtenerRankingGoleadores({
    PeriodoRanking periodo = PeriodoRanking.historico,
  });

  /// E006-HU-003: Obtiene mis estadisticas personales
  Future<Either<Failure, MisEstadisticasResponseModel>> obtenerMisEstadisticas({
    required String grupoId,
  });

  /// E006-HU-004: Obtiene historial de fechas finalizadas
  /// CA-001, CA-007, CA-008
  Future<Either<Failure, HistorialFechasResponseModel>> obtenerHistorialFechas({
    required String grupoId,
    int? anio,
    int? mes,
    bool soloMias = false,
  });

  /// E006-HU-004: Obtiene detalle de resultados de una fecha
  /// CA-002 a CA-006
  Future<Either<Failure, DetalleFechaResultadosModel>> obtenerDetalleFechaResultados({
    required String fechaId,
    required String grupoId,
  });

  /// E006-HU-005: Obtiene estadisticas mensuales del grupo
  /// CA-001 a CA-008
  Future<Either<Failure, EstadisticasMensualesResponseModel>> obtenerEstadisticasMensuales({
    required String grupoId,
    required int anio,
    required int mes,
  });
}
