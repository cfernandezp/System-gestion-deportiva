import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/partidos_repository.dart';
import '../datasources/partidos_remote_datasource.dart';
import '../models/iniciar_partido_response_model.dart';
import '../models/pausar_partido_response_model.dart';
import '../models/reanudar_partido_response_model.dart';
import '../models/obtener_partido_activo_response_model.dart';
// E004-HU-003: Registrar Gol
import '../models/registrar_gol_response_model.dart';
import '../models/eliminar_gol_response_model.dart';
import '../models/obtener_goles_response_model.dart';
// E004-HU-004: Ver Score en Vivo
import '../models/score_partido_response_model.dart';
// E004-HU-005: Finalizar Partido
import '../models/finalizar_partido_response_model.dart';
// Lista de partidos
import '../models/listar_partidos_response_model.dart';
// E004-HU-007: Resumen de Jornada
import '../models/resumen_jornada_model.dart';

/// Implementacion del repositorio de partidos
/// E004-HU-001: Iniciar Partido
/// E004-HU-003: Registrar Gol
/// E004-HU-004: Ver Score en Vivo
/// E004-HU-005: Finalizar Partido
class PartidosRepositoryImpl implements PartidosRepository {
  final PartidosRemoteDataSource remoteDataSource;

  PartidosRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, IniciarPartidoResponseModel>> iniciarPartido({
    required String fechaId,
    required String equipoLocal,
    required String equipoVisitante,
  }) async {
    try {
      final result = await remoteDataSource.iniciarPartido(
        fechaId: fechaId,
        equipoLocal: equipoLocal,
        equipoVisitante: equipoVisitante,
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
        message: 'Error inesperado al iniciar partido: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, PausarPartidoResponseModel>> pausarPartido(
      String partidoId) async {
    try {
      final result = await remoteDataSource.pausarPartido(partidoId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al pausar partido: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, ReanudarPartidoResponseModel>> reanudarPartido(
      String partidoId) async {
    try {
      final result = await remoteDataSource.reanudarPartido(partidoId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al reanudar partido: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, ObtenerPartidoActivoResponseModel>>
      obtenerPartidoActivo(String fechaId) async {
    try {
      final result = await remoteDataSource.obtenerPartidoActivo(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al obtener partido activo: ${e.toString()}',
      ));
    }
  }

  // ==================== E004-HU-003: Registrar Gol ====================

  @override
  Future<Either<Failure, RegistrarGolResponseModel>> registrarGol({
    required String partidoId,
    required String equipoAnotador,
    String? jugadorId,
    bool esAutogol = false,
  }) async {
    try {
      final result = await remoteDataSource.registrarGol(
        partidoId: partidoId,
        equipoAnotador: equipoAnotador,
        jugadorId: jugadorId,
        esAutogol: esAutogol,
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
        message: 'Error inesperado al registrar gol: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, EliminarGolResponseModel>> eliminarGol(
      String golId) async {
    try {
      final result = await remoteDataSource.eliminarGol(golId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al eliminar gol: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, ObtenerGolesResponseModel>> obtenerGolesPartido(
      String partidoId) async {
    try {
      final result = await remoteDataSource.obtenerGolesPartido(partidoId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al obtener goles: ${e.toString()}',
      ));
    }
  }

  // ==================== E004-HU-004: Ver Score en Vivo ====================

  @override
  Future<Either<Failure, ScorePartidoResponseModel>> obtenerScorePartido(
      String partidoId) async {
    try {
      final result = await remoteDataSource.obtenerScorePartido(partidoId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al obtener score: ${e.toString()}',
      ));
    }
  }

  // ==================== E004-HU-005: Finalizar Partido ====================

  @override
  Future<Either<Failure, FinalizarPartidoResponseModel>> finalizarPartido(
    String partidoId, {
    bool confirmarAnticipado = false,
  }) async {
    try {
      final result = await remoteDataSource.finalizarPartido(
        partidoId,
        confirmarAnticipado: confirmarAnticipado,
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
        message: 'Error inesperado al finalizar partido: ${e.toString()}',
      ));
    }
  }

  // ==================== Lista de Partidos ====================

  @override
  Future<Either<Failure, ListarPartidosResponseModel>> listarPartidosFecha(
      String fechaId) async {
    try {
      final result = await remoteDataSource.listarPartidosFecha(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al listar partidos: ${e.toString()}',
      ));
    }
  }

  // ==================== E004-HU-007: Resumen de Jornada ====================

  @override
  Future<Either<Failure, ResumenJornadaModel>> obtenerResumenJornada(
      String fechaId) async {
    try {
      final result = await remoteDataSource.obtenerResumenJornada(fechaId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error inesperado al obtener resumen de jornada: ${e.toString()}',
      ));
    }
  }
}
