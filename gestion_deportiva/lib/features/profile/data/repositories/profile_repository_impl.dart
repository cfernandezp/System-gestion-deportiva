import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/perfil_model.dart';

/// Implementacion del repositorio de perfil
/// E002-HU-001: Ver Perfil Propio
/// Maneja errores y convierte Exceptions a Failures
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PerfilResponseModel>> obtenerPerfilPropio() async {
    try {
      final result = await remoteDataSource.obtenerPerfilPropio();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al obtener perfil: ${e.toString()}',
      ));
    }
  }
}
