import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/registro_response_model.dart';
import '../models/validacion_password_model.dart';
import '../models/verificar_estado_model.dart';

/// Interface del DataSource remoto de autenticacion
abstract class AuthRemoteDataSource {
  /// Registra nuevo usuario
  /// RPC: registrar_usuario(p_nombre_completo, p_email, p_password)
  Future<RegistroResponseModel> registrarUsuario({
    required String nombreCompleto,
    required String email,
    required String password,
  });

  /// Valida requisitos de password
  /// RPC: validar_password(p_password)
  Future<ValidacionPasswordModel> validarPassword({
    required String password,
  });

  /// Verifica estado de acceso del usuario
  /// RPC: verificar_estado_usuario(p_auth_user_id)
  Future<VerificarEstadoModel> verificarEstadoUsuario({
    required String authUserId,
  });
}

/// Implementacion del DataSource remoto de autenticacion
/// Llama a las funciones RPC de Supabase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabase;

  AuthRemoteDataSourceImpl({required this.supabase});

  @override
  Future<RegistroResponseModel> registrarUsuario({
    required String nombreCompleto,
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.rpc(
        'registrar_usuario',
        params: {
          'p_nombre_completo': nombreCompleto,
          'p_email': email,
          'p_password': password,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return RegistroResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al registrar usuario',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al registrar usuario: ${e.toString()}',
      );
    }
  }

  @override
  Future<ValidacionPasswordModel> validarPassword({
    required String password,
  }) async {
    try {
      final response = await supabase.rpc(
        'validar_password',
        params: {
          'p_password': password,
        },
      );

      final responseMap = response as Map<String, dynamic>;
      return ValidacionPasswordModel.fromJson(responseMap);
    } catch (e) {
      throw ServerException(
        message: 'Error al validar password: ${e.toString()}',
      );
    }
  }

  @override
  Future<VerificarEstadoModel> verificarEstadoUsuario({
    required String authUserId,
  }) async {
    try {
      final response = await supabase.rpc(
        'verificar_estado_usuario',
        params: {
          'p_auth_user_id': authUserId,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return VerificarEstadoModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al verificar estado',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error al verificar estado: ${e.toString()}',
      );
    }
  }
}
