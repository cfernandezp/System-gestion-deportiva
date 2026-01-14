import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/login_response_model.dart';
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

  /// Inicia sesion de usuario
  /// RPC: iniciar_sesion(p_email, p_password)
  /// HU-002: CA-002, CA-003, RN-002, RN-003, RN-004, RN-005, RN-007
  Future<LoginResponseModel> iniciarSesion({
    required String email,
    required String password,
  });

  /// Verifica si un email esta bloqueado por intentos fallidos
  /// RPC: verificar_bloqueo_login(p_email)
  /// HU-002: RN-007
  Future<VerificarBloqueoModel> verificarBloqueoLogin({
    required String email,
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

  @override
  Future<LoginResponseModel> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.rpc(
        'iniciar_sesion',
        params: {
          'p_email': email,
          'p_password': password,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return LoginResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al iniciar sesion',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al iniciar sesion: ${e.toString()}',
      );
    }
  }

  @override
  Future<VerificarBloqueoModel> verificarBloqueoLogin({
    required String email,
  }) async {
    try {
      final response = await supabase.rpc(
        'verificar_bloqueo_login',
        params: {
          'p_email': email,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return VerificarBloqueoModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al verificar bloqueo',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error al verificar bloqueo: ${e.toString()}',
      );
    }
  }
}
