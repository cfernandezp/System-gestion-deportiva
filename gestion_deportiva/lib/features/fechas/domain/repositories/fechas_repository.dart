import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/crear_fecha_request_model.dart';
import '../../data/models/crear_fecha_response_model.dart';
import '../../data/models/inscripcion_model.dart';
import '../../data/models/fecha_detalle_model.dart';
import '../../data/models/fecha_disponible_model.dart';

/// Interface del repositorio de fechas
/// E003-HU-001: Crear Fecha
/// E003-HU-002: Inscribirse a Fecha
abstract class FechasRepository {
  /// Crea una nueva fecha de pichanga
  /// CA-001 a CA-007, RN-001 a RN-007
  /// Returns: `Either<Failure, CrearFechaResponseModel>`
  Future<Either<Failure, CrearFechaResponseModel>> crearFecha(
      CrearFechaRequestModel request);

  // ==================== E003-HU-002: Inscribirse a Fecha ====================

  /// Inscribe al usuario actual a una fecha
  /// CA-002, CA-003, RN-001 a RN-004
  /// Returns: `Either<Failure, InscripcionResponseModel>`
  Future<Either<Failure, InscripcionResponseModel>> inscribirseFecha(
      String fechaId);

  /// Cancela la inscripcion del usuario a una fecha
  /// CA-004
  /// Returns: `Either<Failure, CancelarInscripcionResponseModel>`
  Future<Either<Failure, CancelarInscripcionResponseModel>> cancelarInscripcion(
      String fechaId);

  /// Obtiene el detalle de una fecha con sus inscritos
  /// CA-001, CA-004, CA-005, CA-006
  /// Returns: `Either<Failure, FechaDetalleResponseModel>`
  Future<Either<Failure, FechaDetalleResponseModel>> obtenerFechaDetalle(
      String fechaId);

  /// Lista todas las fechas disponibles (abiertas)
  /// RN-002
  /// Returns: `Either<Failure, ListarFechasDisponiblesResponseModel>`
  Future<Either<Failure, ListarFechasDisponiblesResponseModel>>
      listarFechasDisponibles();
}
