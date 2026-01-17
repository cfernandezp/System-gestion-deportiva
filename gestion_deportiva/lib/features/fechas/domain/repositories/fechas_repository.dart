import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/crear_fecha_request_model.dart';
import '../../data/models/crear_fecha_response_model.dart';

/// Interface del repositorio de fechas
/// E003-HU-001: Crear Fecha
abstract class FechasRepository {
  /// Crea una nueva fecha de pichanga
  /// CA-001 a CA-007, RN-001 a RN-007
  /// Returns: `Either<Failure, CrearFechaResponseModel>`
  Future<Either<Failure, CrearFechaResponseModel>> crearFecha(
      CrearFechaRequestModel request);
}
