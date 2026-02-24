import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/estadisticas_repository.dart';
import '../datasources/estadisticas_remote_datasource.dart';
import '../models/models.dart';

/// Implementacion del repositorio de estadisticas
/// E006-HU-001: Ranking de Goleadores
/// E006-HU-003: Mis Estadisticas
/// E006-HU-004: Resultados por Fecha
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

  @override
  Future<Either<Failure, MisEstadisticasResponseModel>> obtenerMisEstadisticas({
    required String grupoId,
  }) async {
    try {
      final result = await remoteDataSource.obtenerMisEstadisticas(
        grupoId: grupoId,
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

  @override
  Future<Either<Failure, HistorialFechasResponseModel>> obtenerHistorialFechas({
    required String grupoId,
    int? anio,
    int? mes,
    bool soloMias = false,
  }) async {
    try {
      final result = await remoteDataSource.obtenerHistorialFechas(
        grupoId: grupoId,
        anio: anio,
        mes: mes,
        soloMias: soloMias,
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

  @override
  Future<Either<Failure, DetalleFechaResultadosModel>> obtenerDetalleFechaResultados({
    required String fechaId,
    required String grupoId,
  }) async {
    try {
      final result = await remoteDataSource.obtenerDetalleFechaResultados(
        fechaId: fechaId,
        grupoId: grupoId,
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

  @override
  Future<Either<Failure, EstadisticasMensualesResponseModel>> obtenerEstadisticasMensuales({
    required String grupoId,
    required int anio,
    required int mes,
  }) async {
    try {
      final result = await remoteDataSource.obtenerEstadisticasMensuales(
        grupoId: grupoId,
        anio: anio,
        mes: mes,
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
