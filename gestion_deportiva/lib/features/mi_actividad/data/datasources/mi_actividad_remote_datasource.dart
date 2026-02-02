import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/models.dart';

/// Interface del DataSource remoto de mi actividad
/// E004-HU-008: Mi Actividad en Vivo
abstract class MiActividadRemoteDataSource {
  /// Obtiene la actividad en vivo del jugador
  /// RPC: obtener_mi_actividad_vivo()
  /// CA-001, CA-002, CA-003, CA-004, CA-005, CA-006, CA-007
  /// RN-001, RN-002, RN-003, RN-004
  Future<MiActividadResponseModel> obtenerMiActividadVivo();

  /// Stream de cambios en tiempo real de goles
  /// RN-006: Supabase Realtime para actualizaciones automaticas
  Stream<void> observarCambiosGoles(String fechaId);

  /// Stream de cambios en tiempo real de partidos
  /// RN-006: Supabase Realtime para actualizaciones automaticas
  Stream<void> observarCambiosPartidos(String fechaId);
}

/// Implementacion del DataSource remoto de mi actividad
/// Llama a las funciones RPC de Supabase y maneja Realtime
class MiActividadRemoteDataSourceImpl implements MiActividadRemoteDataSource {
  final supabase_lib.SupabaseClient supabase;

  MiActividadRemoteDataSourceImpl({required this.supabase});

  @override
  Future<MiActividadResponseModel> obtenerMiActividadVivo() async {
    try {
      // RPC: obtener_mi_actividad_vivo()
      // CA-001 a CA-007
      // RN-001 a RN-004
      final response = await supabase.rpc('obtener_mi_actividad_vivo');

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return MiActividadResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] as String? ??
              'Error al obtener actividad en vivo',
          code: error['code'] as String?,
          hint: error['hint'] as String?,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message:
            'Error de conexion al obtener actividad en vivo: ${e.toString()}',
      );
    }
  }

  @override
  Stream<void> observarCambiosGoles(String fechaId) {
    // RN-006: Suscripcion Realtime a tabla goles filtrada por fecha_id
    // CA-009: Actualizacion automatica al registrar gol
    return supabase
        .from('goles')
        .stream(primaryKey: ['id'])
        .eq('fecha_id', fechaId)
        .map((_) {});
  }

  @override
  Stream<void> observarCambiosPartidos(String fechaId) {
    // RN-006: Suscripcion Realtime a tabla partidos filtrada por fecha_id
    // CA-009: Actualizacion automatica al cambiar estado de partido
    return supabase
        .from('partidos')
        .stream(primaryKey: ['id'])
        .eq('fecha_id', fechaId)
        .map((_) {});
  }
}
