import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/fechas_repository.dart';
import '../datasources/fechas_remote_datasource.dart';
import '../models/crear_fecha_request_model.dart';
import '../models/crear_fecha_response_model.dart';

/// Implementacion del repositorio de fechas
/// E003-HU-001: Crear Fecha
class FechasRepositoryImpl implements FechasRepository {
  final FechasRemoteDataSource remoteDataSource;

  FechasRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, CrearFechaResponseModel>> crearFecha(
      CrearFechaRequestModel request) async {
    try {
      final result = await remoteDataSource.crearFecha(request);
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
