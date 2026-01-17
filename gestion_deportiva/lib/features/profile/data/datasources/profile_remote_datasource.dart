import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/perfil_model.dart';

/// Interface del DataSource remoto de perfil
/// E002-HU-001: Ver Perfil Propio
/// E002-HU-002: Editar Perfil Propio
abstract class ProfileRemoteDataSource {
  /// Obtiene el perfil del usuario autenticado
  /// RPC: obtener_perfil_propio()
  /// CA-001, CA-002, CA-003, RN-001
  Future<PerfilResponseModel> obtenerPerfilPropio();

  /// E002-HU-002: Actualiza el perfil del usuario autenticado
  /// RPC: actualizar_perfil_propio()
  /// CA-001 a CA-006, RN-001 a RN-005
  /// Actualizado 2026-01-16: Agregado nombreCompleto como campo editable
  Future<PerfilResponseModel> actualizarPerfilPropio({
    required String nombreCompleto,
    required String apodo,
    String? telefono,
    String? posicionPreferida,
    String? fotoUrl,
  });
}

/// Implementacion del DataSource remoto de perfil
/// Llama a las funciones RPC de Supabase
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final supabase_lib.SupabaseClient supabase;

  ProfileRemoteDataSourceImpl({required this.supabase});

  @override
  Future<PerfilResponseModel> obtenerPerfilPropio() async {
    try {
      // RN-001: La funcion RPC usa auth.uid() para garantizar
      // que solo se obtenga el perfil del usuario autenticado
      final response = await supabase.rpc('obtener_perfil_propio');

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return PerfilResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener perfil',
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

  /// E002-HU-002: Actualiza el perfil del usuario autenticado
  /// RN-001: Valida apodo unico (excepto si no cambio)
  /// RN-002: Actualiza campos permitidos (incluye nombre_completo desde 2026-01-16)
  /// RN-003: Solo puede editar su propio perfil (auth.uid())
  /// RN-004: Valida formato de apodo (2-30 caracteres)
  @override
  Future<PerfilResponseModel> actualizarPerfilPropio({
    required String nombreCompleto,
    required String apodo,
    String? telefono,
    String? posicionPreferida,
    String? fotoUrl,
  }) async {
    try {
      final response = await supabase.rpc(
        'actualizar_perfil_propio',
        params: {
          'p_nombre_completo': nombreCompleto,
          'p_apodo': apodo,
          'p_telefono': telefono,
          'p_posicion_preferida': posicionPreferida,
          'p_foto_url': fotoUrl,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return PerfilResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al actualizar perfil',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al actualizar perfil: ${e.toString()}',
      );
    }
  }
}
