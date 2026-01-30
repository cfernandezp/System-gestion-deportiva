import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/solicitud_pendiente_model.dart';

/// Interface del DataSource remoto de solicitudes
/// E001-HU-006: Gestionar Solicitudes de Registro
///
/// Criterios de Aceptacion:
/// - CA-001: Acceso exclusivo admin (verificar rol)
/// - CA-003: Lista con nombre, email, fecha registro, dias pendiente
/// - CA-004: Ordenar por antiguedad (mas antiguas primero)
/// - CA-005: Aprobar con seleccion de rol (default "Jugador")
/// - CA-006: Rechazar con motivo opcional
abstract class SolicitudesRemoteDataSource {
  /// Obtiene la lista de usuarios pendientes de aprobacion
  /// RPC: obtener_usuarios_pendientes()
  /// CA-003, CA-004
  Future<ObtenerUsuariosPendientesResponseModel> obtenerUsuariosPendientes();

  /// Aprueba un usuario pendiente asignandole un rol
  /// RPC: aprobar_usuario(p_usuario_id, p_rol)
  /// CA-005: p_rol puede ser 'jugador', 'admin', 'arbitro', 'delegado'
  Future<AprobarUsuarioResponseModel> aprobarUsuario({
    required String usuarioId,
    required String rol,
  });

  /// Rechaza un usuario pendiente con motivo opcional
  /// RPC: rechazar_usuario(p_usuario_id, p_motivo)
  /// CA-006: p_motivo es opcional
  Future<RechazarUsuarioResponseModel> rechazarUsuario({
    required String usuarioId,
    String? motivo,
  });
}

/// Implementacion del DataSource remoto de solicitudes
/// Llama a las funciones RPC de Supabase
class SolicitudesRemoteDataSourceImpl implements SolicitudesRemoteDataSource {
  final supabase_lib.SupabaseClient supabase;

  SolicitudesRemoteDataSourceImpl({required this.supabase});

  @override
  Future<ObtenerUsuariosPendientesResponseModel>
      obtenerUsuariosPendientes() async {
    try {
      // RPC: obtener_usuarios_pendientes()
      // CA-003: Lista con nombre, email, fecha registro, dias pendiente
      // CA-004: Ordenar por antiguedad (mas antiguas primero)
      final response = await supabase.rpc('obtener_usuarios_pendientes');

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ObtenerUsuariosPendientesResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener solicitudes pendientes',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al obtener solicitudes: ${e.toString()}',
      );
    }
  }

  @override
  Future<AprobarUsuarioResponseModel> aprobarUsuario({
    required String usuarioId,
    required String rol,
  }) async {
    try {
      // RPC: aprobar_usuario(p_usuario_id, p_rol)
      // CA-005: p_rol puede ser 'jugador', 'admin', 'arbitro', 'delegado'
      final response = await supabase.rpc(
        'aprobar_usuario',
        params: {
          'p_usuario_id': usuarioId,
          'p_rol': rol,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return AprobarUsuarioResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al aprobar usuario',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al aprobar usuario: ${e.toString()}',
      );
    }
  }

  @override
  Future<RechazarUsuarioResponseModel> rechazarUsuario({
    required String usuarioId,
    String? motivo,
  }) async {
    try {
      // RPC: rechazar_usuario(p_usuario_id, p_motivo)
      // CA-006: p_motivo es opcional
      final response = await supabase.rpc(
        'rechazar_usuario',
        params: {
          'p_usuario_id': usuarioId,
          'p_motivo': motivo,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return RechazarUsuarioResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al rechazar usuario',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al rechazar usuario: ${e.toString()}',
      );
    }
  }
}
