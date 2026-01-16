import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/jugador_model.dart';

/// Interface del DataSource remoto de jugadores
/// E002-HU-003: Lista de Jugadores
abstract class JugadoresRemoteDataSource {
  /// Obtiene la lista de jugadores aprobados
  /// RPC: listar_jugadores()
  /// CA-001 a CA-005, RN-001 a RN-005
  Future<ListaJugadoresResponseModel> listarJugadores({
    String? busqueda,
    OrdenCampo ordenCampo = OrdenCampo.nombre,
    OrdenDireccion ordenDireccion = OrdenDireccion.asc,
  });
}

/// Implementacion del DataSource remoto de jugadores
/// Llama a las funciones RPC de Supabase
class JugadoresRemoteDataSourceImpl implements JugadoresRemoteDataSource {
  final supabase_lib.SupabaseClient supabase;

  JugadoresRemoteDataSourceImpl({required this.supabase});

  @override
  Future<ListaJugadoresResponseModel> listarJugadores({
    String? busqueda,
    OrdenCampo ordenCampo = OrdenCampo.nombre,
    OrdenDireccion ordenDireccion = OrdenDireccion.asc,
  }) async {
    try {
      final response = await supabase.rpc(
        'listar_jugadores',
        params: {
          'p_busqueda': busqueda,
          'p_orden_campo': ordenCampo.valor,
          'p_orden_direccion': ordenDireccion.valor,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ListaJugadoresResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener lista de jugadores',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener jugadores: ${e.toString()}',
      );
    }
  }
}
