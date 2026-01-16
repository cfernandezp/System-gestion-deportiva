import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/jugador_model.dart';

/// Interface del repositorio de jugadores
/// E002-HU-003: Lista de Jugadores
abstract class JugadoresRepository {
  /// Obtiene la lista de jugadores aprobados
  /// CA-001 a CA-005, RN-001 a RN-005
  Future<Either<Failure, ListaJugadoresResponseModel>> listarJugadores({
    String? busqueda,
    OrdenCampo ordenCampo = OrdenCampo.nombre,
    OrdenDireccion ordenDireccion = OrdenDireccion.asc,
  });
}
