import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/models.dart';

/// Interface del DataSource remoto de estadisticas
/// E006-HU-001: Ranking de Goleadores
/// E006-HU-003: Mis Estadisticas
/// E006-HU-004: Resultados por Fecha
abstract class EstadisticasRemoteDataSource {
  /// Obtiene el ranking de goleadores
  /// RPC: obtener_ranking_goleadores(p_periodo)
  /// CA-001 a CA-007, RN-001 a RN-006
  Future<RankingGoleadoresResponseModel> obtenerRankingGoleadores({
    PeriodoRanking periodo = PeriodoRanking.historico,
  });

  /// E006-HU-003: Obtiene mis estadisticas personales
  /// RPC: obtener_mis_estadisticas(p_grupo_id)
  Future<MisEstadisticasResponseModel> obtenerMisEstadisticas({
    required String grupoId,
  });

  /// E006-HU-004: Obtiene historial de fechas finalizadas
  /// RPC: obtener_historial_fechas(p_grupo_id, p_anio?, p_mes?, p_solo_mias?)
  /// CA-001, CA-007, CA-008
  Future<HistorialFechasResponseModel> obtenerHistorialFechas({
    required String grupoId,
    int? anio,
    int? mes,
    bool soloMias,
  });

  /// E006-HU-004: Obtiene detalle de resultados de una fecha
  /// RPC: obtener_detalle_fecha_resultados(p_fecha_id, p_grupo_id)
  /// CA-002 a CA-006
  Future<DetalleFechaResultadosModel> obtenerDetalleFechaResultados({
    required String fechaId,
    required String grupoId,
  });

  /// E006-HU-005: Obtiene estadisticas mensuales del grupo
  /// RPC: obtener_estadisticas_mensuales(p_grupo_id, p_anio, p_mes)
  /// CA-001 a CA-008
  Future<EstadisticasMensualesResponseModel> obtenerEstadisticasMensuales({
    required String grupoId,
    required int anio,
    required int mes,
  });
}

/// Implementacion del DataSource remoto de estadisticas
/// Llama a las funciones RPC de Supabase
/// E006-HU-001, E006-HU-003, E006-HU-004, E006-HU-005
class EstadisticasRemoteDataSourceImpl implements EstadisticasRemoteDataSource {
  final supabase_lib.SupabaseClient supabase;

  EstadisticasRemoteDataSourceImpl({required this.supabase});

  @override
  Future<RankingGoleadoresResponseModel> obtenerRankingGoleadores({
    PeriodoRanking periodo = PeriodoRanking.historico,
  }) async {
    try {
      final response = await supabase.rpc(
        'obtener_ranking_goleadores',
        params: {
          'p_periodo': periodo.valor,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return RankingGoleadoresResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener ranking de goleadores',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener ranking: ${e.toString()}',
      );
    }
  }

  @override
  Future<MisEstadisticasResponseModel> obtenerMisEstadisticas({
    required String grupoId,
  }) async {
    try {
      final response = await supabase.rpc(
        'obtener_mis_estadisticas',
        params: {
          'p_grupo_id': grupoId,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return MisEstadisticasResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener mis estadisticas',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener estadisticas: ${e.toString()}',
      );
    }
  }

  @override
  Future<HistorialFechasResponseModel> obtenerHistorialFechas({
    required String grupoId,
    int? anio,
    int? mes,
    bool soloMias = false,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_grupo_id': grupoId,
        'p_solo_mias': soloMias,
      };
      if (anio != null) params['p_anio'] = anio;
      if (mes != null) params['p_mes'] = mes;

      final response = await supabase.rpc(
        'obtener_historial_fechas',
        params: params,
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return HistorialFechasResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener historial de fechas',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener historial: ${e.toString()}',
      );
    }
  }

  @override
  Future<DetalleFechaResultadosModel> obtenerDetalleFechaResultados({
    required String fechaId,
    required String grupoId,
  }) async {
    try {
      final response = await supabase.rpc(
        'obtener_detalle_fecha_resultados',
        params: {
          'p_fecha_id': fechaId,
          'p_grupo_id': grupoId,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return DetalleFechaResultadosModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener detalle de fecha',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener detalle: ${e.toString()}',
      );
    }
  }

  @override
  Future<EstadisticasMensualesResponseModel> obtenerEstadisticasMensuales({
    required String grupoId,
    required int anio,
    required int mes,
  }) async {
    try {
      final response = await supabase.rpc(
        'obtener_estadisticas_mensuales',
        params: {
          'p_grupo_id': grupoId,
          'p_anio': anio,
          'p_mes': mes,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return EstadisticasMensualesResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener estadisticas mensuales',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener estadisticas mensuales: ${e.toString()}',
      );
    }
  }
}
