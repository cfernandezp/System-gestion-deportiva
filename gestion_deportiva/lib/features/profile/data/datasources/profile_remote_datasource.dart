import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/perfil_model.dart';

/// Interface del DataSource remoto de perfil
/// E002-HU-001: Ver Perfil Propio
abstract class ProfileRemoteDataSource {
  /// Obtiene el perfil del usuario autenticado
  /// RPC: obtener_perfil_propio()
  /// CA-001, CA-002, CA-003, RN-001
  Future<PerfilResponseModel> obtenerPerfilPropio();
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
}
