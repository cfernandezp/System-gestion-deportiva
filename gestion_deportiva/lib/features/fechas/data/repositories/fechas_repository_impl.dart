import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/fechas_repository.dart';
import '../datasources/fechas_remote_datasource.dart';
import '../models/crear_fecha_request_model.dart';
import '../models/crear_fecha_response_model.dart';
import '../models/inscripcion_model.dart';
import '../models/fecha_detalle_model.dart';
import '../models/fecha_disponible_model.dart';

/// Implementacion del repositorio de fechas
/// E003-HU-001: Crear Fecha
/// E003-HU-002: Inscribirse a Fecha
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

  // ==================== E003-HU-002: Inscribirse a Fecha ====================

  @override
  Future<Either<Failure, InscripcionResponseModel>> inscribirseFecha(
      String fechaId) async {
    try {
      final result = await remoteDataSource.inscribirseFecha(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al inscribirse: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, CancelarInscripcionResponseModel>> cancelarInscripcion(
      String fechaId) async {
    try {
      final result = await remoteDataSource.cancelarInscripcion(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al cancelar: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, FechaDetalleResponseModel>> obtenerFechaDetalle(
      String fechaId) async {
    try {
      final result = await remoteDataSource.obtenerFechaDetalle(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al obtener detalle: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, ListarFechasDisponiblesResponseModel>>
      listarFechasDisponibles() async {
    try {
      final result = await remoteDataSource.listarFechasDisponibles();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al listar fechas: ${e.toString()}',
      ));
    }
  }
}
