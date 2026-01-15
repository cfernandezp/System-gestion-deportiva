import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

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
  final supabase_lib.SupabaseClient supabase;

  AuthRemoteDataSourceImpl({required this.supabase});

  @override
  Future<RegistroResponseModel> registrarUsuario({
    required String nombreCompleto,
    required String email,
    required String password,
  }) async {
    String? authUserId;

    debugPrint('========== REGISTRO USUARIO - INICIO ==========');
    debugPrint('[REGISTRO] Email: $email');
    debugPrint('[REGISTRO] Nombre: $nombreCompleto');
    debugPrint('[REGISTRO] Password length: ${password.length}');

    try {
      // PASO 1: Crear usuario en auth.users usando Supabase Auth nativo
      // Esto garantiza que el hash de contrasena sea compatible con signInWithPassword()
      debugPrint('[REGISTRO] PASO 1: Llamando supabase.auth.signUp()...');
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'nombre_completo': nombreCompleto},
      );

      debugPrint('[REGISTRO] signUp() completado');
      debugPrint('[REGISTRO] authResponse.user: ${authResponse.user}');
      debugPrint('[REGISTRO] authResponse.user?.id: ${authResponse.user?.id}');
      debugPrint('[REGISTRO] authResponse.user?.email: ${authResponse.user?.email}');
      debugPrint('[REGISTRO] authResponse.session: ${authResponse.session != null ? "EXISTE" : "NULL"}');

      // Verificar que se creo el usuario en auth
      if (authResponse.user == null) {
        debugPrint('[REGISTRO] ERROR: authResponse.user es NULL');
        throw ServerException(
          message: 'Error al crear usuario en autenticacion',
          code: 'AUTH_SIGNUP_FAILED',
          hint: 'signup_failed',
        );
      }

      authUserId = authResponse.user!.id;
      debugPrint('[REGISTRO] Usuario creado en auth.users con ID: $authUserId');

      // PASO 2: Completar registro en tabla usuarios
      // Esta funcion RPC crea el perfil y notifica a admins
      debugPrint('[REGISTRO] PASO 2: Llamando RPC completar_registro_usuario()...');
      final response = await supabase.rpc(
        'completar_registro_usuario',
        params: {
          'p_auth_user_id': authUserId,
          'p_nombre_completo': nombreCompleto,
          'p_email': email,
        },
      );

      debugPrint('[REGISTRO] RPC completar_registro_usuario response: $response');

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        debugPrint('[REGISTRO] EXITO: Registro completado correctamente');
        // Cerrar sesion despues del registro (usuario debe esperar aprobacion)
        await supabase.auth.signOut();
        debugPrint('[REGISTRO] Sesion cerrada post-registro');
        debugPrint('========== REGISTRO USUARIO - FIN (EXITO) ==========');
        return RegistroResponseModel.fromJson(responseMap);
      } else {
        debugPrint('[REGISTRO] ERROR: completar_registro_usuario fallo');
        debugPrint('[REGISTRO] Response error: ${responseMap['error']}');
        // Si falla completar_registro, eliminar usuario de auth (rollback)
        await _rollbackAuthUser(authUserId);

        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al completar registro',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on supabase_lib.AuthException catch (e) {
      // Manejar errores especificos de Supabase Auth
      debugPrint('[REGISTRO] AuthException capturada:');
      debugPrint('[REGISTRO]   message: ${e.message}');
      debugPrint('[REGISTRO]   statusCode: ${e.statusCode}');
      debugPrint('========== REGISTRO USUARIO - FIN (AUTH ERROR) ==========');

      String hint = 'auth_error';
      String message = e.message;

      if (e.message.contains('already registered') ||
          e.message.contains('already exists')) {
        hint = 'email_duplicado';
        message = 'El email ya esta registrado en el sistema';
      } else if (e.message.contains('Invalid email')) {
        hint = 'email_formato_invalido';
        message = 'El formato del email no es valido';
      } else if (e.message.contains('Password')) {
        hint = 'password_invalido';
        message = 'La contrasena no cumple los requisitos';
      }

      throw ServerException(
        message: message,
        code: 'AUTH_ERROR',
        hint: hint,
      );
    } on ServerException {
      debugPrint('========== REGISTRO USUARIO - FIN (SERVER ERROR) ==========');
      rethrow;
    } catch (e) {
      debugPrint('[REGISTRO] Exception generica: ${e.runtimeType}');
      debugPrint('[REGISTRO] Exception message: $e');
      debugPrint('========== REGISTRO USUARIO - FIN (EXCEPTION) ==========');
      // Si algo falla despues de crear el auth user, hacer rollback
      if (authUserId != null) {
        await _rollbackAuthUser(authUserId);
      }

      throw ServerException(
        message: 'Error de conexion al registrar usuario: ${e.toString()}',
      );
    }
  }

  /// Elimina un usuario de auth.users cuando falla completar_registro
  /// Esto es un rollback para mantener consistencia
  Future<void> _rollbackAuthUser(String authUserId) async {
    try {
      // Primero cerrar sesion
      await supabase.auth.signOut();

      // Intentar eliminar via RPC (requiere service_role, puede fallar)
      // Si falla, el usuario quedara en auth.users pero sin perfil
      // Un admin puede limpiarlo manualmente despues
      await supabase.rpc(
        'eliminar_usuario_auth',
        params: {'p_auth_user_id': authUserId},
      );
    } catch (_) {
      // Ignorar errores de rollback - ya estamos en un estado de error
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
    debugPrint('========== INICIAR SESION - INICIO ==========');
    debugPrint('[LOGIN] Email: $email');
    debugPrint('[LOGIN] Password length: ${password.length}');

    try {
      // 1. Verificar si la cuenta esta bloqueada por intentos fallidos
      // RN-007: Bloqueo temporal despues de 5 intentos fallidos
      debugPrint('[LOGIN] PASO 1: Verificando bloqueo de cuenta...');
      final bloqueoResponse = await supabase.rpc(
        'verificar_bloqueo_login',
        params: {
          'p_email': email,
        },
      );

      debugPrint('[LOGIN] verificar_bloqueo_login response: $bloqueoResponse');

      final bloqueoMap = bloqueoResponse as Map<String, dynamic>;

      if (bloqueoMap['success'] == true) {
        final bloqueoData = bloqueoMap['data'] as Map<String, dynamic>? ?? {};
        final estaBloqueado = bloqueoData['bloqueado'] ?? false;
        debugPrint('[LOGIN] Esta bloqueado: $estaBloqueado');

        if (estaBloqueado) {
          final minutosRestantes = bloqueoData['minutos_restantes'] ?? 15;
          debugPrint('[LOGIN] Cuenta bloqueada por $minutosRestantes minutos');
          debugPrint('========== INICIAR SESION - FIN (BLOQUEADO) ==========');
          throw ServerException(
            message:
                'Cuenta bloqueada temporalmente. Intente nuevamente en $minutosRestantes minutos.',
            code: 'CUENTA_BLOQUEADA',
            hint: 'cuenta_bloqueada',
          );
        }
      }

      // 2. Intentar autenticacion con Supabase Auth
      // Esto valida credenciales contra auth.users
      debugPrint('[LOGIN] PASO 2: Llamando signInWithPassword()...');
      debugPrint('[LOGIN]   email: $email');
      debugPrint('[LOGIN]   password: ****** (${password.length} caracteres)');

      try {
        final authResponse = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        debugPrint('[LOGIN] signInWithPassword() EXITOSO!');
        debugPrint('[LOGIN] authResponse.user: ${authResponse.user}');
        debugPrint('[LOGIN] authResponse.user?.id: ${authResponse.user?.id}');
        debugPrint('[LOGIN] authResponse.user?.email: ${authResponse.user?.email}');
        debugPrint('[LOGIN] authResponse.session: ${authResponse.session != null ? "EXISTE" : "NULL"}');

      } on supabase_lib.AuthException catch (authError) {
        // 3. Si falla auth, registrar intento fallido
        // RN-007: Registrar intentos fallidos para bloqueo temporal
        debugPrint('[LOGIN] !!!!! AuthException capturada !!!!!');
        debugPrint('[LOGIN] AuthException.message: ${authError.message}');
        debugPrint('[LOGIN] AuthException.statusCode: ${authError.statusCode}');
        debugPrint('[LOGIN] AuthException.toString(): ${authError.toString()}');
        debugPrint('[LOGIN] AuthException.runtimeType: ${authError.runtimeType}');

        debugPrint('[LOGIN] Registrando intento fallido...');
        try {
          await supabase.rpc(
            'registrar_intento_fallido',
            params: {
              'p_email': email,
            },
          );
          debugPrint('[LOGIN] Intento fallido registrado');
        } catch (e) {
          debugPrint('[LOGIN] Error al registrar intento fallido: $e');
          // Ignorar errores al registrar intento fallido
        }

        debugPrint('========== INICIAR SESION - FIN (AUTH ERROR) ==========');
        throw ServerException(
          message: authError.message,
          code: 'CREDENCIALES_INVALIDAS',
          hint: 'credenciales_invalidas',
        );
      }

      // 4. Auth exitoso - Verificar estado del usuario en la BD
      // RN-003: Solo usuarios aprobados pueden acceder
      debugPrint('[LOGIN] PASO 3: Verificando estado del usuario en BD...');
      final sesionResponse = await supabase.rpc('verificar_sesion_usuario');

      debugPrint('[LOGIN] verificar_sesion_usuario response: $sesionResponse');

      final sesionMap = sesionResponse as Map<String, dynamic>;

      if (sesionMap['success'] != true) {
        debugPrint('[LOGIN] verificar_sesion_usuario fallo');
        // Si falla la verificacion, cerrar sesion
        await supabase.auth.signOut();
        final error = sesionMap['error'] as Map<String, dynamic>? ?? {};
        debugPrint('[LOGIN] Error: $error');
        debugPrint('========== INICIAR SESION - FIN (SESION ERROR) ==========');
        throw ServerException(
          message: error['message'] ?? 'Error al verificar sesion',
          code: error['code'],
          hint: error['hint'],
        );
      }

      final sesionData = sesionMap['data'] as Map<String, dynamic>? ?? {};
      final estado = sesionData['estado'] ?? '';
      final puedeAcceder = sesionData['puede_acceder'] ?? false;

      debugPrint('[LOGIN] Estado usuario: $estado');
      debugPrint('[LOGIN] Puede acceder: $puedeAcceder');

      // 5. Verificar si el usuario puede acceder segun su estado
      // RN-003, RN-004, RN-005: Validar estados pendiente/rechazado
      if (!puedeAcceder) {
        debugPrint('[LOGIN] Usuario NO puede acceder, cerrando sesion...');
        // Cerrar sesion si no puede acceder
        await supabase.auth.signOut();

        if (estado == 'pendiente_aprobacion') {
          debugPrint('========== INICIAR SESION - FIN (PENDIENTE) ==========');
          throw ServerException(
            message:
                'Tu cuenta esta pendiente de aprobacion. Por favor espera a que un administrador la apruebe.',
            code: 'USUARIO_PENDIENTE',
            hint: 'usuario_pendiente',
          );
        } else if (estado == 'rechazado') {
          debugPrint('========== INICIAR SESION - FIN (RECHAZADO) ==========');
          throw ServerException(
            message:
                'Tu solicitud de registro ha sido rechazada. Contacta al administrador para mas informacion.',
            code: 'USUARIO_RECHAZADO',
            hint: 'usuario_rechazado',
          );
        } else if (estado == 'inactivo') {
          debugPrint('========== INICIAR SESION - FIN (INACTIVO) ==========');
          throw ServerException(
            message:
                'Tu cuenta ha sido desactivada. Contacta al administrador.',
            code: 'USUARIO_INACTIVO',
            hint: 'usuario_inactivo',
          );
        } else {
          debugPrint('========== INICIAR SESION - FIN (ACCESO DENEGADO) ==========');
          throw ServerException(
            message: 'No tienes acceso al sistema.',
            code: 'ACCESO_DENEGADO',
            hint: 'acceso_denegado',
          );
        }
      }

      // 6. Retornar datos del usuario autenticado
      debugPrint('[LOGIN] LOGIN EXITOSO!');
      debugPrint('[LOGIN] Usuario: ${sesionData['nombre_completo']}');
      debugPrint('[LOGIN] Rol: ${sesionData['rol']}');
      debugPrint('========== INICIAR SESION - FIN (EXITO) ==========');
      return LoginResponseModel.fromJson(sesionMap);
    } on ServerException {
      rethrow;
    } on supabase_lib.AuthException catch (e) {
      // Captura cualquier AuthException no manejada en el try interno
      debugPrint('[LOGIN] AuthException NO MANEJADA:');
      debugPrint('[LOGIN]   message: ${e.message}');
      debugPrint('[LOGIN]   statusCode: ${e.statusCode}');
      debugPrint('========== INICIAR SESION - FIN (UNHANDLED AUTH) ==========');
      throw ServerException(
        message: e.message,
        code: 'AUTH_ERROR',
        hint: 'credenciales_invalidas',
      );
    } catch (e) {
      debugPrint('[LOGIN] Exception generica: ${e.runtimeType}');
      debugPrint('[LOGIN] Exception: $e');
      debugPrint('========== INICIAR SESION - FIN (EXCEPTION) ==========');
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
