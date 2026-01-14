import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
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
}
