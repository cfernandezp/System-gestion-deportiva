import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/jugador_model.dart';
import '../models/jugador_perfil_model.dart';

/// Interface del DataSource remoto de jugadores
/// E002-HU-003: Lista de Jugadores
/// E002-HU-004: Ver Perfil de Otro Jugador
abstract class JugadoresRemoteDataSource {
  /// Obtiene la lista de jugadores aprobados
  /// RPC: listar_jugadores()
  /// CA-001 a CA-005, RN-001 a RN-005
  Future<ListaJugadoresResponseModel> listarJugadores({
    String? busqueda,
    OrdenCampo ordenCampo = OrdenCampo.nombre,
    OrdenDireccion ordenDireccion = OrdenDireccion.asc,
  });

  /// Obtiene el perfil publico de un jugador
  /// RPC: obtener_perfil_jugador(p_jugador_id)
  /// E002-HU-004: CA-001 a CA-004, RN-001 a RN-004
  Future<JugadorPerfilResponseModel> obtenerPerfilJugador(String jugadorId);
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

  @override
  Future<JugadorPerfilResponseModel> obtenerPerfilJugador(
      String jugadorId) async {
    try {
      final response = await supabase.rpc(
        'obtener_perfil_jugador',
        params: {
          'p_jugador_id': jugadorId,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return JugadorPerfilResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener perfil del jugador',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener perfil: ${e.toString()}',
      );
    }
  }
}
