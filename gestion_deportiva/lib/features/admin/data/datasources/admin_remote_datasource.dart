import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/usuario_admin_model.dart';

/// Interface del DataSource remoto de administracion
/// HU-005: Gestion de Roles
abstract class AdminRemoteDataSource {
  /// Lista todos los usuarios con su rol actual
  /// RPC: listar_usuarios(p_busqueda)
  /// HU-005: CA-001, CA-005, RN-006, RN-007
  Future<ListarUsuariosResponseModel> listarUsuarios({
    String? busqueda,
  });

  /// Cambia el rol de un usuario especifico
  /// RPC: cambiar_rol_usuario(p_usuario_id, p_nuevo_rol)
  /// HU-005: CA-002, CA-003, CA-004, RN-001 a RN-005
  Future<CambiarRolResponseModel> cambiarRolUsuario({
    required String usuarioId,
    required String nuevoRol,
  });
}

/// Implementacion del DataSource remoto de administracion
/// Llama a las funciones RPC de Supabase
class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final SupabaseClient supabase;

  AdminRemoteDataSourceImpl({required this.supabase});

  @override
  Future<ListarUsuariosResponseModel> listarUsuarios({
    String? busqueda,
  }) async {
    try {
      final response = await supabase.rpc(
        'listar_usuarios',
        params: {
          'p_busqueda': busqueda,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ListarUsuariosResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al listar usuarios',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al listar usuarios: ${e.toString()}',
      );
    }
  }

  @override
  Future<CambiarRolResponseModel> cambiarRolUsuario({
    required String usuarioId,
    required String nuevoRol,
  }) async {
    try {
      final response = await supabase.rpc(
        'cambiar_rol_usuario',
        params: {
          'p_usuario_id': usuarioId,
          'p_nuevo_rol': nuevoRol,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return CambiarRolResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al cambiar rol',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al cambiar rol: ${e.toString()}',
      );
    }
  }
}
