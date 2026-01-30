import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/solicitudes_repository.dart';
import '../datasources/solicitudes_remote_datasource.dart';
import '../models/solicitud_pendiente_model.dart';

/// Implementacion del repositorio de solicitudes
/// E001-HU-006: Gestionar Solicitudes de Registro
///
/// Criterios de Aceptacion:
/// - CA-001: Acceso exclusivo admin
/// - CA-003: Lista con nombre, email, fecha registro, dias pendiente
/// - CA-004: Ordenar por antiguedad
/// - CA-005: Aprobar con seleccion de rol
/// - CA-006: Rechazar con motivo opcional
class SolicitudesRepositoryImpl implements SolicitudesRepository {
  final SolicitudesRemoteDataSource remoteDataSource;

  SolicitudesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ObtenerUsuariosPendientesResponseModel>>
      obtenerUsuariosPendientes() async {
    try {
      final result = await remoteDataSource.obtenerUsuariosPendientes();
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
  Future<Either<Failure, AprobarUsuarioResponseModel>> aprobarUsuario({
    required String usuarioId,
    required String rol,
  }) async {
    try {
      final result = await remoteDataSource.aprobarUsuario(
        usuarioId: usuarioId,
        rol: rol,
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
        message: 'Error inesperado al aprobar usuario: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, RechazarUsuarioResponseModel>> rechazarUsuario({
    required String usuarioId,
    String? motivo,
  }) async {
    try {
      final result = await remoteDataSource.rechazarUsuario(
        usuarioId: usuarioId,
        motivo: motivo,
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
        message: 'Error inesperado al rechazar usuario: ${e.toString()}',
      ));
    }
  }
}
