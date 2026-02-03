import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/estadisticas_repository.dart';
import '../datasources/estadisticas_remote_datasource.dart';
import '../models/models.dart';

/// Implementacion del repositorio de estadisticas
/// E006-HU-001: Ranking de Goleadores
class EstadisticasRepositoryImpl implements EstadisticasRepository {
  final EstadisticasRemoteDataSource remoteDataSource;

  EstadisticasRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, RankingGoleadoresResponseModel>> obtenerRankingGoleadores({
    PeriodoRanking periodo = PeriodoRanking.historico,
  }) async {
    try {
      final result = await remoteDataSource.obtenerRankingGoleadores(
        periodo: periodo,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado: ${e.toString()}',
      ));
    }
  }
}
