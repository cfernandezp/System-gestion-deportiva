import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/plan_model.dart';
import '../models/permiso_result_model.dart';

/// DataSource remoto para operaciones de planes
/// E000-HU-002: Infraestructura de Planes y Limites
abstract class PlanesRemoteDataSource {
  /// RPC: obtener_planes()
  /// CA-001: Consultar planes disponibles
  Future<List<PlanModel>> obtenerPlanes();

  /// RPC: obtener_plan_admin()
  /// Obtiene el plan del admin autenticado
  /// RN-002: Default a Gratis si no tiene plan
  Future<PlanModel> obtenerPlanAdmin();

  /// RPC: verificar_permiso_plan(p_plan_id, p_tipo_validacion, p_recurso, p_cantidad_actual)
  /// CA-013 / RN-009: Consulta centralizada "puede hacer X?"
  Future<PermisoResultModel> verificarPermiso({
    required String planId,
    required String tipoValidacion,
    required String recurso,
    int cantidadActual,
  });
}

/// Implementacion con Supabase
class PlanesRemoteDataSourceImpl implements PlanesRemoteDataSource {
  final supabase_lib.SupabaseClient supabase;

  PlanesRemoteDataSourceImpl({required this.supabase});

  @override
  Future<List<PlanModel>> obtenerPlanes() async {
    try {
      debugPrint('[PlanesDS] Obteniendo planes disponibles...');

      final response = await supabase.rpc('obtener_planes');
      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        final data = responseMap['data'] as List<dynamic>? ?? [];
        final planes =
            data.map((p) => PlanModel.fromJson(p as Map<String, dynamic>)).toList();
        debugPrint('[PlanesDS] ${planes.length} planes obtenidos');
        return planes;
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener planes',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('[PlanesDS] Error obtenerPlanes: $e');
      throw ServerException(message: 'Error de conexion: ${e.toString()}');
    }
  }

  @override
  Future<PlanModel> obtenerPlanAdmin() async {
    try {
      debugPrint('[PlanesDS] Obteniendo plan del admin...');

      final response = await supabase.rpc('obtener_plan_admin');
      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        final data = responseMap['data'] as Map<String, dynamic>;
        final plan = PlanModel.fromJson(data);
        debugPrint('[PlanesDS] Plan admin: ${plan.nombre} (${plan.slug})');
        return plan;
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener plan del admin',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('[PlanesDS] Error obtenerPlanAdmin: $e');
      throw ServerException(message: 'Error de conexion: ${e.toString()}');
    }
  }

  @override
  Future<PermisoResultModel> verificarPermiso({
    required String planId,
    required String tipoValidacion,
    required String recurso,
    int cantidadActual = 0,
  }) async {
    try {
      debugPrint(
          '[PlanesDS] Verificando permiso: tipo=$tipoValidacion, recurso=$recurso, cantidad=$cantidadActual');

      final response = await supabase.rpc(
        'verificar_permiso_plan',
        params: {
          'p_plan_id': planId,
          'p_tipo_validacion': tipoValidacion,
          'p_recurso': recurso,
          'p_cantidad_actual': cantidadActual,
        },
      );

      final responseMap = response as Map<String, dynamic>;
      final resultado = PermisoResultModel.fromJson(responseMap);
      debugPrint(
          '[PlanesDS] Resultado permiso: permitido=${resultado.permitido}, motivo=${resultado.motivo}');
      return resultado;
    } catch (e) {
      debugPrint('[PlanesDS] Error verificarPermiso: $e');
      throw ServerException(message: 'Error de conexion: ${e.toString()}');
    }
  }
}
