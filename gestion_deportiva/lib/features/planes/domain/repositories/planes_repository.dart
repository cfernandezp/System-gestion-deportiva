import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/permiso_result_model.dart';

/// Repositorio abstracto para operaciones de planes
/// E000-HU-002: Infraestructura de Planes y Limites
/// CA-001 a CA-015, RN-001 a RN-012
abstract class PlanesRepository {
  /// CA-001: Obtener todos los planes disponibles
  Future<Either<Failure, List<PlanModel>>> obtenerPlanes();

  /// Obtener plan actual del admin autenticado
  /// RN-002: Default a Gratis
  Future<Either<Failure, PlanModel>> obtenerPlanAdmin();

  /// CA-013 / RN-009: Consulta centralizada "puede hacer X?"
  /// Valida limites numericos o feature flags contra el plan
  Future<Either<Failure, PermisoResultModel>> verificarPermiso({
    required String planId,
    required String tipoValidacion,
    required String recurso,
    int cantidadActual,
  });
}
