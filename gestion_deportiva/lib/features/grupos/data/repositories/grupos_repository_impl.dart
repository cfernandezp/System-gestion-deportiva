import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/grupos_repository.dart';
import '../datasources/grupos_remote_datasource.dart';
import '../models/crear_grupo_response_model.dart';
import '../models/editar_grupo_response_model.dart';
import '../models/grupo_model.dart';
import '../models/invitar_jugador_response_model.dart';
import '../models/miembro_grupo_model.dart';
import '../models/mi_grupo_model.dart';

/// Implementacion del repositorio de grupos
/// E002-HU-001: Crear Grupo Deportivo
/// Convierte ServerException a ServerFailure (patron Either)
class GruposRepositoryImpl implements GruposRepository {
  final GruposRemoteDataSource remoteDataSource;

  GruposRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, CrearGrupoResponseModel>> crearGrupo({
    required String nombre,
    String? lema,
    String? reglas,
    String? logoUrl,
  }) async {
    try {
      final result = await remoteDataSource.crearGrupo(
        nombre: nombre,
        lema: lema,
        reglas: reglas,
        logoUrl: logoUrl,
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
  Future<Either<Failure, String>> subirLogo(File imagen) async {
    try {
      final url = await remoteDataSource.subirLogoGrupo(imagen);
      return Right(url);
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
  Future<Either<Failure, int>> contarGruposComoAdmin() async {
    try {
      final count = await remoteDataSource.contarGruposComoAdmin();
      return Right(count);
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
  Future<Either<Failure, List<MiGrupoModel>>> obtenerMisGrupos() async {
    try {
      final result = await remoteDataSource.obtenerMisGrupos();
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
  Future<Either<Failure, void>> registrarAccesoGrupo(String grupoId) async {
    try {
      await remoteDataSource.registrarAccesoGrupo(grupoId);
      return const Right(null);
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
  Future<Either<Failure, InvitarJugadorResponseModel>> invitarJugadorGrupo({
    required String grupoId,
    required String celular,
  }) async {
    try {
      final result = await remoteDataSource.invitarJugadorGrupo(
        grupoId: grupoId,
        celular: celular,
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
  Future<Either<Failure, List<MiembroGrupoModel>>> obtenerMiembrosGrupo(String grupoId) async {
    try {
      final result = await remoteDataSource.obtenerMiembrosGrupo(grupoId);
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
  Future<Either<Failure, GrupoModel>> obtenerDetalleGrupo(String grupoId) async {
    try {
      final result = await remoteDataSource.obtenerDetalleGrupo(grupoId);
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
  Future<Either<Failure, EditarGrupoResponseModel>> editarGrupo({
    required String grupoId,
    required String nombre,
    String? lema,
    String? reglas,
    String? logoUrl,
  }) async {
    try {
      final result = await remoteDataSource.editarGrupo(
        grupoId: grupoId,
        nombre: nombre,
        lema: lema,
        reglas: reglas,
        logoUrl: logoUrl,
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
  Future<Either<Failure, void>> eliminarJugadorGrupo({
    required String grupoId,
    required String miembroId,
  }) async {
    try {
      await remoteDataSource.eliminarJugadorGrupo(
        grupoId: grupoId,
        miembroId: miembroId,
      );
      return const Right(null);
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
