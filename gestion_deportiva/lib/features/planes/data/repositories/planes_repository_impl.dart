import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/planes_repository.dart';
import '../datasources/planes_remote_datasource.dart';
import '../models/plan_model.dart';
import '../models/permiso_result_model.dart';

/// Implementacion del repositorio de planes
/// E000-HU-002: Infraestructura de Planes y Limites
/// Convierte ServerException a ServerFailure (patron Either)
class PlanesRepositoryImpl implements PlanesRepository {
  final PlanesRemoteDataSource remoteDataSource;

  PlanesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PlanModel>>> obtenerPlanes() async {
    try {
      final result = await remoteDataSource.obtenerPlanes();
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
  Future<Either<Failure, PlanModel>> obtenerPlanAdmin() async {
    try {
      final result = await remoteDataSource.obtenerPlanAdmin();
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
  Future<Either<Failure, PermisoResultModel>> verificarPermiso({
    required String planId,
    required String tipoValidacion,
    required String recurso,
    int cantidadActual = 0,
  }) async {
    try {
      final result = await remoteDataSource.verificarPermiso(
        planId: planId,
        tipoValidacion: tipoValidacion,
        recurso: recurso,
        cantidadActual: cantidadActual,
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
