import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/mi_actividad_repository.dart';
import '../datasources/mi_actividad_remote_datasource.dart';
import '../models/models.dart';

/// Implementacion del repository de Mi Actividad
/// E004-HU-008: Mi Actividad en Vivo
class MiActividadRepositoryImpl implements MiActividadRepository {
  final MiActividadRemoteDataSource remoteDataSource;

  MiActividadRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, MiActividadResponseModel>>
      obtenerMiActividadVivo() async {
    try {
      final response = await remoteDataSource.obtenerMiActividadVivo();
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al obtener actividad: ${e.toString()}',
      ));
    }
  }

  @override
  Stream<void> observarCambiosGoles(String fechaId) {
    return remoteDataSource.observarCambiosGoles(fechaId);
  }

  @override
  Stream<void> observarCambiosPartidos(String fechaId) {
    return remoteDataSource.observarCambiosPartidos(fechaId);
  }
}
