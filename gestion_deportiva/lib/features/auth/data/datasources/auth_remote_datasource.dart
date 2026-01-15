import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/cerrar_sesion_response_model.dart';
import '../models/login_response_model.dart';
import '../models/recuperacion_response_model.dart';
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

  /// Cierra la sesion del usuario actual
  /// RPC: cerrar_sesion() + supabase.auth.signOut()
  /// HU-004: CA-002, RN-002
  Future<CerrarSesionResponseModel> cerrarSesion();

  /// Solicita recuperacion de contrasena
  /// RPC: solicitar_recuperacion_contrasena(p_email)
  /// HU-003: CA-001, CA-002, CA-003, RN-001
  Future<SolicitudRecuperacionModel> solicitarRecuperacion({
    required String email,
  });

  /// Valida token de recuperacion de contrasena
  /// RPC: validar_token_recuperacion(p_token)
  /// HU-003: CA-004, CA-005, RN-002, RN-003
  Future<ValidarTokenModel> validarTokenRecuperacion({
    required String token,
  });

  /// Restablece contrasena con token valido
  /// RPC: restablecer_contrasena(p_token, p_nueva_contrasena, p_confirmar_contrasena)
  /// HU-003: CA-004, CA-005, CA-006, RN-002, RN-003, RN-004, RN-005, RN-006
  Future<RestablecerContrasenaModel> restablecerContrasena({
    required String token,
    required String nuevaContrasena,
    required String confirmarContrasena,
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

  @override
  Future<CerrarSesionResponseModel> cerrarSesion() async {
    try {
      // 1. Llamar RPC para registrar logout en auditoria
      // HU-004: RN-002 - Invalidacion inmediata de sesion
      final response = await supabase.rpc('cerrar_sesion');

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        // 2. Cerrar sesion en Supabase Auth (invalida JWT token)
        // HU-004: RN-004 - No persistencia de credenciales post-cierre
        await supabase.auth.signOut();

        return CerrarSesionResponseModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al cerrar sesion',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al cerrar sesion: ${e.toString()}',
      );
    }
  }

  @override
  Future<SolicitudRecuperacionModel> solicitarRecuperacion({
    required String email,
  }) async {
    try {
      final response = await supabase.rpc(
        'solicitar_recuperacion_contrasena',
        params: {
          'p_email': email,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      // RN-001: Siempre retorna success con mensaje generico por seguridad
      if (responseMap['success'] == true) {
        return SolicitudRecuperacionModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al solicitar recuperacion',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al solicitar recuperacion: ${e.toString()}',
      );
    }
  }

  @override
  Future<ValidarTokenModel> validarTokenRecuperacion({
    required String token,
  }) async {
    try {
      final response = await supabase.rpc(
        'validar_token_recuperacion',
        params: {
          'p_token': token,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return ValidarTokenModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al validar token',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al validar token: ${e.toString()}',
      );
    }
  }

  @override
  Future<RestablecerContrasenaModel> restablecerContrasena({
    required String token,
    required String nuevaContrasena,
    required String confirmarContrasena,
  }) async {
    try {
      final response = await supabase.rpc(
        'restablecer_contrasena',
        params: {
          'p_token': token,
          'p_nueva_contrasena': nuevaContrasena,
          'p_confirmar_contrasena': confirmarContrasena,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return RestablecerContrasenaModel.fromJson(responseMap);
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al restablecer contrasena',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al restablecer contrasena: ${e.toString()}',
      );
    }
  }
}
