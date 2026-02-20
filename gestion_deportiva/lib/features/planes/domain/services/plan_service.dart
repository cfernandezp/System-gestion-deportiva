import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/permiso_result_model.dart';
import '../repositories/planes_repository.dart';

/// Servicio centralizado para validacion de permisos de plan
/// E000-HU-002: CA-013, RN-009
///
/// Uso desde cualquier feature:
/// ```dart
/// final planService = sl<PlanService>();
///
/// // Verificar limite numerico
/// final puede = await planService.verificarLimite(
///   recurso: 'jugadores_por_grupo',
///   cantidadActual: 24,
/// );
/// puede.fold(
///   (failure) => mostrarError(failure.message),
///   (resultado) {
///     if (resultado.permitido) { agregar(); }
///     else { navegarAUpgrade(resultado); }
///   },
/// );
///
/// // Verificar feature flag
/// final tieneStats = await planService.verificarFeature('estadisticas_avanzadas');
/// ```
class PlanService {
  final PlanesRepository _repository;

  /// Cache del plan actual del admin (evita llamadas repetidas)
  PlanModel? _planActual;

  PlanService({required PlanesRepository repository})
      : _repository = repository;

  /// Plan actual cacheado (null si no se ha cargado)
  PlanModel? get planActual => _planActual;

  /// Carga el plan del admin autenticado
  /// RN-002: Default a Gratis si no tiene plan
  Future<Either<Failure, PlanModel>> cargarPlanAdmin({
    bool forzarRecarga = false,
  }) async {
    if (_planActual != null && !forzarRecarga) {
      return Right(_planActual!);
    }

    final result = await _repository.obtenerPlanAdmin();
    result.fold(
      (_) {},
      (plan) {
        _planActual = plan;
        debugPrint('[PlanService] Plan cargado: ${plan.nombre} (${plan.slug})');
      },
    );
    return result;
  }

  /// CA-001: Obtener todos los planes disponibles
  Future<Either<Failure, List<PlanModel>>> obtenerPlanes() {
    return _repository.obtenerPlanes();
  }

  /// CA-013 / RN-009: Verificar limite numerico
  /// Requiere que el plan este cargado previamente
  ///
  /// Recursos validos:
  /// - 'grupos_por_admin'
  /// - 'jugadores_por_grupo'
  /// - 'invitados_por_grupo'
  /// - 'coadmins_por_grupo'
  /// - 'equipos_por_fecha'
  /// - 'tamano_logo_mb'
  Future<Either<Failure, PermisoResultModel>> verificarLimite({
    required String recurso,
    required int cantidadActual,
  }) async {
    // Asegurar que el plan esta cargado
    final planResult = await cargarPlanAdmin();

    return planResult.fold(
      (failure) => Left(failure),
      (plan) => _repository.verificarPermiso(
        planId: plan.id,
        tipoValidacion: 'limite',
        recurso: recurso,
        cantidadActual: cantidadActual,
      ),
    );
  }

  /// CA-011 / RN-007 / RN-008: Verificar feature flag
  /// Requiere que el plan este cargado previamente
  ///
  /// Features validas:
  /// - 'estadisticas_avanzadas'
  /// - 'temas_personalizados_grupo'
  Future<Either<Failure, PermisoResultModel>> verificarFeature(
    String feature,
  ) async {
    // Asegurar que el plan esta cargado
    final planResult = await cargarPlanAdmin();

    return planResult.fold(
      (failure) => Left(failure),
      (plan) => _repository.verificarPermiso(
        planId: plan.id,
        tipoValidacion: 'feature',
        recurso: feature,
      ),
    );
  }

  /// CA-014: Verificar si un limite configurable es valido
  /// El admin puede reducir limites pero no por debajo del uso actual
  /// ni por encima del maximo del plan
  /// RN-010: No reducir por debajo del uso actual
  bool esLimiteConfigurableValido({
    required String recurso,
    required int valorDeseado,
    required int usoActual,
  }) {
    if (_planActual == null) return false;

    final limiteMaximo = _planActual!.getLimite(recurso);

    // RN-010: No menor al uso actual
    if (valorDeseado < usoActual) return false;

    // CA-014: No mayor al maximo del plan
    if (valorDeseado > limiteMaximo) return false;

    return true;
  }

  /// Limpia el cache del plan (ej: al cerrar sesion)
  void limpiarCache() {
    _planActual = null;
    debugPrint('[PlanService] Cache de plan limpiado');
  }
}
