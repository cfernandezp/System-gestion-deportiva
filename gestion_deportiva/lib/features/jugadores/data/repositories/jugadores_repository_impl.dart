import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/jugadores_repository.dart';
import '../datasources/jugadores_remote_datasource.dart';
import '../models/jugador_model.dart';
import '../models/jugador_perfil_model.dart';

/// Implementacion del repositorio de jugadores
/// E002-HU-003: Lista de Jugadores
/// E002-HU-004: Ver Perfil de Otro Jugador
class JugadoresRepositoryImpl implements JugadoresRepository {
  final JugadoresRemoteDataSource remoteDataSource;

  JugadoresRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ListaJugadoresResponseModel>> listarJugadores({
    String? busqueda,
    OrdenCampo ordenCampo = OrdenCampo.nombre,
    OrdenDireccion ordenDireccion = OrdenDireccion.asc,
  }) async {
    try {
      final result = await remoteDataSource.listarJugadores(
        busqueda: busqueda,
        ordenCampo: ordenCampo,
        ordenDireccion: ordenDireccion,
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
  Future<Either<Failure, JugadorPerfilResponseModel>> obtenerPerfilJugador(
      String jugadorId) async {
    try {
      final result = await remoteDataSource.obtenerPerfilJugador(jugadorId);
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
