import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/models.dart';

/// Interface del DataSource remoto de estadisticas
/// E006-HU-001: Ranking de Goleadores
abstract class EstadisticasRemoteDataSource {
  /// Obtiene el ranking de goleadores
  /// RPC: obtener_ranking_goleadores(p_periodo)
  /// CA-001 a CA-007, RN-001 a RN-006
  Future<RankingGoleadoresResponseModel> obtenerRankingGoleadores({
    PeriodoRanking periodo = PeriodoRanking.historico,
  });
}

/// Implementacion del DataSource remoto de estadisticas
/// Llama a las funciones RPC de Supabase
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
}
