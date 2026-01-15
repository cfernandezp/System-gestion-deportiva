import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/cerrar_sesion_response_model.dart';
import '../../data/models/login_response_model.dart';
import '../../data/models/recuperacion_response_model.dart';
import '../../data/models/registro_response_model.dart';
import '../../data/models/validacion_password_model.dart';
import '../../data/models/verificar_estado_model.dart';

/// Interface del repositorio de autenticacion
/// Define el contrato para operaciones de auth
abstract class AuthRepository {
  /// Registra un nuevo usuario en el sistema
  /// Retorna [RegistroResponseModel] si exito, [Failure] si error
  Future<Either<Failure, RegistroResponseModel>> registrarUsuario({
    required String nombreCompleto,
    required String email,
    required String password,
  });

  /// Valida los requisitos de seguridad del password
  /// Retorna [ValidacionPasswordModel] con resultado de validacion
  Future<Either<Failure, ValidacionPasswordModel>> validarPassword({
    required String password,
  });

  /// Verifica si el usuario puede acceder al sistema
  /// Retorna [VerificarEstadoModel] con estado y permisos
  Future<Either<Failure, VerificarEstadoModel>> verificarEstadoUsuario({
    required String authUserId,
  });

  /// Inicia sesion de usuario
  /// HU-002: CA-002, CA-003
  /// Retorna [LoginResponseModel] si exito, [Failure] si error
  Future<Either<Failure, LoginResponseModel>> iniciarSesion({
    required String email,
    required String password,
  });

  /// Verifica si un email esta bloqueado por intentos fallidos
  /// HU-002: RN-007
  /// Retorna [VerificarBloqueoModel] con estado de bloqueo
  Future<Either<Failure, VerificarBloqueoModel>> verificarBloqueoLogin({
    required String email,
  });

  /// Cierra la sesion del usuario actual
  /// HU-004: CA-002, RN-002, RN-004
  /// Retorna [CerrarSesionResponseModel] si exito, [Failure] si error
  Future<Either<Failure, CerrarSesionResponseModel>> cerrarSesion();

  /// Solicita recuperacion de contrasena
  /// HU-003: CA-001, CA-002, CA-003, RN-001
  Future<Either<Failure, SolicitudRecuperacionModel>> solicitarRecuperacion({
    required String email,
  });

  /// Valida token de recuperacion
  /// HU-003: CA-004, CA-005
  Future<Either<Failure, ValidarTokenModel>> validarTokenRecuperacion({
    required String token,
  });

  /// Restablece contrasena con token valido
  /// HU-003: CA-006, RN-004, RN-005, RN-006
  Future<Either<Failure, RestablecerContrasenaModel>> restablecerContrasena({
    required String token,
    required String nuevaContrasena,
    required String confirmarContrasena,
  });
}
