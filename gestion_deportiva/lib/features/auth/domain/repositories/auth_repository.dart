import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/login_response_model.dart';
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
}
