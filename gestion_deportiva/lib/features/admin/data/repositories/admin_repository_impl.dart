import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';
import '../models/usuario_admin_model.dart';

/// Implementacion del repositorio de administracion
/// HU-005: Gestion de Roles
/// Maneja errores y convierte excepciones a Failures
class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ListarUsuariosResponseModel>> listarUsuarios({
    String? busqueda,
  }) async {
    try {
      final result = await remoteDataSource.listarUsuarios(
        busqueda: busqueda,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }

  @override
  Future<Either<Failure, CambiarRolResponseModel>> cambiarRolUsuario({
    required String usuarioId,
    required String nuevoRol,
  }) async {
    try {
      final result = await remoteDataSource.cambiarRolUsuario(
        usuarioId: usuarioId,
        nuevoRol: nuevoRol,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }
}
