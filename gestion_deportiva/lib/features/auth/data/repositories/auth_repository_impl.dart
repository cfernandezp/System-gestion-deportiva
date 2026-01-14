import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_response_model.dart';
import '../models/registro_response_model.dart';
import '../models/validacion_password_model.dart';
import '../models/verificar_estado_model.dart';

/// Implementacion del repositorio de autenticacion
/// Maneja errores y convierte excepciones a Failures
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, RegistroResponseModel>> registrarUsuario({
    required String nombreCompleto,
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.registrarUsuario(
        nombreCompleto: nombreCompleto,
        email: email,
        password: password,
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
  Future<Either<Failure, ValidacionPasswordModel>> validarPassword({
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.validarPassword(
        password: password,
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
  Future<Either<Failure, VerificarEstadoModel>> verificarEstadoUsuario({
    required String authUserId,
  }) async {
    try {
      final result = await remoteDataSource.verificarEstadoUsuario(
        authUserId: authUserId,
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
  Future<Either<Failure, LoginResponseModel>> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.iniciarSesion(
        email: email,
        password: password,
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
  Future<Either<Failure, VerificarBloqueoModel>> verificarBloqueoLogin({
    required String email,
  }) async {
    try {
      final result = await remoteDataSource.verificarBloqueoLogin(
        email: email,
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
